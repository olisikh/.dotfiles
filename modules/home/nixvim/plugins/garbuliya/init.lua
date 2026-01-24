local api = vim.api
local fn = vim.fn
local bo = vim.bo
local json = vim.json
local log = vim.log
local tbl_extend = vim.tbl_extend
local schedule = vim.schedule

local ns = api.nvim_create_namespace("garbuliya")

local M = {}

M.config = {
	endpoint = "http://localhost:11434/v1/chat/completions",
	api_key = "",
	model = "opencode/grok-code-fast-1",
	temperature = 0.2,
	keymap = "<leader>gi",
	curl_path = "curl",
	notify = true,
	system_prompt = [[
You are an expert software engineer focused on correctness, performance, and simplicity.

You write production-quality code.
You do not explain your reasoning unless explicitly asked.
You strictly follow instructions and constraints.
]],
}

local function notify(msg, level)
	if not M.config.notify then
		return
	end
	schedule(function()
		vim.notify(msg, level or log.levels.INFO, { title = "garbuliya" })
	end)
end

local function split_lines(s)
	local out = {}
	s = (s or ""):gsub("\r\n", "\n")
	for line in (s .. "\n"):gmatch("(.-)\n") do
		out[#out + 1] = line
	end
	return out
end

local function mark_label(bufnr, mark_id)
	local name = api.nvim_buf_get_name(bufnr)
	name = (name == "" and "[No Name]") or fn.fnamemodify(name, ":t")

	local pos = api.nvim_buf_get_extmark_by_id(bufnr, ns, mark_id, {})
	if not pos or not pos[1] then
		return name
	end

	return ("%s:%d:%d"):format(name, pos[1] + 1, pos[2] + 1)
end

local function fidget_progress(title, message)
	local ok, fidget = pcall(require, "fidget.progress")
	if not ok then
		return nil
	end
	return fidget.handle.create({
		title = title,
		message = message,
		percentage = nil,
	})
end

-- Spinner
local SPINNER = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function update_mark(bufnr, mark_id, opts)
	local pos = api.nvim_buf_get_extmark_by_id(bufnr, ns, mark_id, {})
	if not pos or not pos[1] then
		return false
	end
	api.nvim_buf_set_extmark(bufnr, ns, pos[1], pos[2], tbl_extend("force", { id = mark_id }, opts or {}))
	return true
end

local function start_spinner(bufnr, mark_id, label_fn)
	local i = 1
	local timer = vim.loop.new_timer()

	timer:start(0, 120, function()
		schedule(function()
			if not api.nvim_buf_is_valid(bufnr) then
				timer:stop()
				timer:close()
				return
			end

			local icon = SPINNER[i]
			i = (i % #SPINNER) + 1

			local label = label_fn and label_fn() or ""
			local msg = (label ~= "" and (" " .. label) or "")

			local ok = update_mark(bufnr, mark_id, {
				virt_text = { { icon .. msg, "Comment" } },
				virt_text_pos = "eol",
				hl_mode = "combine",
			})

			if not ok then
				timer:stop()
				timer:close()
			end
		end)
	end)

	return timer
end

local function stop_spinner(bufnr, mark_id, timer)
	if timer then
		timer:stop()
		timer:close()
	end
	schedule(function()
		if api.nvim_buf_is_valid(bufnr) then
			update_mark(bufnr, mark_id, { virt_text = nil })
		end
	end)
end

-- Selection helpers
local function get_visual_range()
	local mode = fn.mode()
	if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
		return nil
	end
	local srow, scol = unpack(api.nvim_buf_get_mark(0, "<"))
	local erow, ecol = unpack(api.nvim_buf_get_mark(0, ">"))
	return srow - 1, scol, erow - 1, ecol
end

local function ts_find_nearest_function_range()
	-- No require(); just guard get_parser
	local ok, parser = pcall(vim.treesitter.get_parser, 0)
	if not ok or not parser then
		return nil
	end

	local tree = parser:parse()[1]
	if not tree then
		return nil
	end
	local root = tree:root()
	if not root then
		return nil
	end

	local row, col = unpack(api.nvim_win_get_cursor(0))
	row = row - 1

	local node = root:named_descendant_for_range(row, col, row, col)
	while node do
		local t = node:type() or ""
		if t:find("function") or t:find("method") or t:find("declaration") or t:find("definition") then
			local sr, sc, er, ec = node:range()
			if (er - sr) <= 4000 then
				return sr, sc, er, ec
			end
		end
		node = node:parent()
	end
	return nil
end

local function compute_target_range()
	local sr, sc, er, ec = ts_find_nearest_function_range()
	if sr then
		return sr, sc, er, ec
	end

	local vr = { get_visual_range() }
	if #vr == 4 then
		return vr[1], vr[2], vr[3], vr[4]
	end

	return nil
end

-- LLM plumbing
local function buf_text(bufnr, sr, sc, er, ec)
	local lines = api.nvim_buf_get_text(bufnr, sr, sc, er, ec, {})
	return table.concat(lines, "\n")
end

local function build_payload(prompt)
	return json.encode({
		model = M.config.model,
		messages = {
			{ role = "system", content = M.config.system_prompt },
			{ role = "user", content = prompt },
		},
		temperature = M.config.temperature,
		stream = false,
	})
end

local function strip_http_headers(raw)
	local i = raw:find("\r\n\r\n", 1, true)
	if i then
		return raw:sub(i + 4)
	end
	i = raw:find("\n\n", 1, true)
	if i then
		return raw:sub(i + 2)
	end
	return raw
end

local function extract_code_from_response(raw_text)
	local body = strip_http_headers(raw_text or "")
	local trimmed = body:match("^%s*(.*)$") or ""
	local first = trimmed:sub(1, 1)
	if first ~= "{" and first ~= "[" then
		return nil, "Non-JSON response (endpoint/auth). First bytes: " .. trimmed:sub(1, 80)
	end

	local ok, obj = pcall(json.decode, body)
	if not ok or type(obj) ~= "table" then
		return nil, "LLM returned invalid JSON"
	end

	local choice = obj.choices and obj.choices[1]
	local content = choice and ((choice.message and choice.message.content) or choice.text or choice.content)

	if type(content) ~= "string" then
		return nil, "Unexpected JSON shape (no choices[1].message.content/text)"
	end

	content = content:gsub("^%s*```[%w_-]*\n", ""):gsub("\n```%s*$", "")
	return content, nil
end

local function run_llm(prompt, cb)
	local payload = build_payload(prompt)

	local args = {
		M.config.curl_path,
		"-sS",
		"--fail-with-body",
		"-X",
		"POST",
		M.config.endpoint,
		"-H",
		"Content-Type: application/json",
		"-d",
		payload,
	}

	if M.config.api_key and M.config.api_key ~= "" then
		args[#args + 1] = "-H"
		args[#args + 1] = "Authorization: Bearer " .. M.config.api_key
	end

	vim.system(args, { text = true }, function(res)
		if res.code ~= 0 then
			cb(nil, ("curl failed (%d): %s"):format(res.code, (res.stderr or ""):gsub("%s+$", "")))
			return
		end
		cb(res.stdout, nil)
	end)
end

-- Public
function M.implement()
	local bufnr = api.nvim_get_current_buf()
	local filetype = bo[bufnr].filetype

	local sr, sc, er, ec = compute_target_range()
	if not sr then
		notify("No function node found and no visual selection.", log.levels.WARN)
		return
	end

	-- Anchors for applying edits (stable, tied to region)
	local start_id = api.nvim_buf_set_extmark(bufnr, ns, sr, sc, { right_gravity = false })
	local end_id = api.nvim_buf_set_extmark(bufnr, ns, er, ec, { right_gravity = true })

	-- Separate anchor for UI: show next to cursor
	local cur = api.nvim_win_get_cursor(0)
	local cur_row = cur[1] - 1
	local cur_col = cur[2]
	local spinner_id = api.nvim_buf_set_extmark(bufnr, ns, cur_row, cur_col, { right_gravity = false })

	local loc = mark_label(bufnr, start_id)

	local spinner_timer = start_spinner(bufnr, spinner_id, function()
		return "garbuliya thinking… (" .. loc .. ")"
	end)
	local progress = fidget_progress("garbuliya", ("Thinking… (%s)"):format(loc))

	local orig = buf_text(bufnr, sr, sc, er, ec)
	if orig:gsub("%s+", "") == "" then
		notify("Selected region is empty.", log.levels.WARN)
		stop_spinner(bufnr, start_id, spinner_timer)
		if progress then
			progress:cancel()
		end
		return
	end

	local prompt = table.concat({
		("Language: %s"):format(filetype ~= "" and filetype or "unknown"),
		[[
Task: Replace the code in the region below with a correct and optimal implementation.

Hard constraints:
- Preserve the existing function signature and surrounding structure.
- Output ONLY the final code. No markdown, no comments, no explanations.
- Do not introduce global state, logging, or side effects.
- Do not allocate unnecessary data structures.
- Prefer the best asymptotic time complexity known for this task.
- Among equally fast solutions, minimize auxiliary space and allocations.
- Prefer iterative solutions over recursion unless recursion is required for optimal asymptotics.
- Handle edge cases and invalid inputs correctly and minimally.

Quality gate (do not output):
- Sanity-check correctness on edge cases.
- Verify time and auxiliary space complexity.
]],
		"=== REGION START ===",
		orig,
		"=== REGION END ===",
	}, "\n")

	run_llm(prompt, function(stdout, err)
		schedule(function()
			local function cleanup(kind)
				-- kind: "cancel" | "finish" | nil
				stop_spinner(bufnr, spinner_id, spinner_timer)
				pcall(api.nvim_buf_del_extmark, bufnr, ns, spinner_id)

				if progress then
					if kind == "cancel" then
						progress:cancel()
					elseif kind == "finish" then
						progress:finish({ message = ("Done (%s)"):format(loc) })
					end
				end

				pcall(api.nvim_buf_del_extmark, bufnr, ns, start_id)
				pcall(api.nvim_buf_del_extmark, bufnr, ns, end_id)
			end

			if err then
				notify(err, log.levels.ERROR)
				cleanup("cancel")
				return
			end

			local code, perr = extract_code_from_response(stdout)
			if perr then
				notify(perr, log.levels.ERROR)
				cleanup("cancel")
				return
			end
			if not code or code:gsub("%s+", "") == "" then
				notify("LLM returned empty output.", log.levels.ERROR)
				cleanup("cancel")
				return
			end

			if not api.nvim_buf_is_valid(bufnr) then
				notify("Buffer no longer valid; not applying.", log.levels.WARN)
				cleanup("cancel")
				return
			end

			local s = api.nvim_buf_get_extmark_by_id(bufnr, ns, start_id, {})
			local e = api.nvim_buf_get_extmark_by_id(bufnr, ns, end_id, {})
			if not s or not s[1] or not e or not e[1] then
				notify("Target region anchor disappeared; not applying.", log.levels.WARN)
				cleanup("cancel")
				return
			end

			local sr2, sc2 = s[1], s[2]
			local er2, ec2 = e[1], e[2]

			if (er2 < sr2) or (er2 == sr2 and ec2 < sc2) then
				notify("Target region became invalid (edits moved anchors); not applying.", log.levels.WARN)
				cleanup("cancel")
				return
			end

			if progress then
				progress:report({ message = ("Applying… (%s)"):format(loc) })
			end

			api.nvim_buf_set_text(bufnr, sr2, sc2, er2, ec2, split_lines(code))
			notify("Applied implementation.")

			cleanup("finish")
		end)
	end)
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	api.nvim_create_user_command("GarbuliyaImplement", function()
		M.implement()
	end, {})

	if M.config.keymap and M.config.keymap ~= "" then
		vim.keymap.set({ "n", "v" }, M.config.keymap, function()
			M.implement()
		end, { desc = "garbuliya: implement (async)" })
	end
end

return M
