local api = vim.api
local fn = vim.fn
local bo = vim.bo
local json = vim.json
local log = vim.log
local tbl_extend = vim.tbl_extend
local schedule = vim.schedule
local uv = vim.loop

local ns = api.nvim_create_namespace("garbuliya")

local M = {}

M.config = {
	opencode_cmd = "opencode",
	model = "opencode/gpt-5.1-codex-mini",
	format = "json",
	notify = true,
	show_fidget = false,

	system_prompt = [[
You are an expert software engineer focused on correctness, performance, and simplicity.

You write concise, readable, maintainable, performant, production-quality code.
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
	local timer = uv.new_timer()

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

local function clear_mark(bufnr, mark_id)
	pcall(api.nvim_buf_del_extmark, bufnr, ns, mark_id)
end

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

local function buf_text(bufnr, sr, sc, er, ec)
	local lines = api.nvim_buf_get_text(bufnr, sr, sc, er, ec, {})
	return table.concat(lines, "\n")
end

local function strip_fences(s)
	return (s or ""):gsub("^%s*```[%w_-]*%s*\n", ""):gsub("\n%s*```%s*$", "")
end

local function extract_code_from_response(raw_text)
	if type(raw_text) ~= "string" or raw_text == "" then
		return nil, "Empty response from opencode"
	end

	local acc = {}
	local saw_any = false

	for line in raw_text:gmatch("[^\n]+") do
		line = line:gsub("^%s+", ""):gsub("%s+$", "")
		if line ~= "" then
			local ok, obj = pcall(json.decode, line)
			if ok and type(obj) == "table" then
				saw_any = true

				if obj.error then
					local msg = obj.error.message or vim.inspect(obj.error)
					return nil, "opencode error: " .. tostring(msg)
				end

				local et = obj.type
				local part = obj.part

				if et == "text" and type(part) == "table" and type(part.text) == "string" and part.text ~= "" then
					acc[#acc + 1] = part.text
				else
					local choice = obj.choices and obj.choices[1]
					local delta = choice and choice.delta and choice.delta.content
					if type(delta) == "string" and delta ~= "" then
						acc[#acc + 1] = delta
					end
					local msg = choice and choice.message and choice.message.content
					if type(msg) == "string" and msg ~= "" then
						acc[#acc + 1] = msg
					end
					if type(obj.text) == "string" and obj.text ~= "" then
						acc[#acc + 1] = obj.text
					end
					if type(obj.content) == "string" and obj.content ~= "" then
						acc[#acc + 1] = obj.content
					end
					if type(part) == "table" and type(part.content) == "string" and part.content ~= "" then
						acc[#acc + 1] = part.content
					end
				end
			end
		end
	end

	if not saw_any then
		return nil, "No JSON events found in opencode output"
	end

	local content = table.concat(acc, "\n"):gsub("\r\n", "\n")
	content = strip_fences(content)

	if content:gsub("%s+", "") == "" then
		return nil, "Could not extract text from opencode events. First bytes: " .. raw_text:sub(1, 300)
	end

	return content, nil
end

local function run_llm_streaming(prompt, on_event, cb)
	local message = table.concat({ M.config.system_prompt, "", prompt }, "\n")

	local cmd = M.config.opencode_cmd or "opencode"
	local args = {
		"run",
		"--format",
		(M.config.format or "json"),
		"--model",
		M.config.model,
		message,
	}

	local stdout = uv.new_pipe(false)
	local stderr = uv.new_pipe(false)

	local out_chunks = {}
	local err_chunks = {}
	local out_buf = ""
	local err_buf = ""

	local function flush_lines(buf, sink, emit)
		while true do
			local nl = buf:find("\n", 1, true)
			if not nl then
				break
			end
			local line = buf:sub(1, nl - 1)
			buf = buf:sub(nl + 1)
			sink[#sink + 1] = line .. "\n"
			if emit then
				pcall(emit, line)
			end
		end
		return buf
	end

	local handle, pid
	handle, pid = uv.spawn(cmd, { args = args, stdio = { nil, stdout, stderr } }, function(code, signal)
		if stdout and not stdout:is_closing() then
			stdout:read_stop()
		end
		if stderr and not stderr:is_closing() then
			stderr:read_stop()
		end

		if out_buf ~= "" then
			out_chunks[#out_chunks + 1] = out_buf
			out_buf = ""
		end
		if err_buf ~= "" then
			err_chunks[#err_chunks + 1] = err_buf
			err_buf = ""
		end

		if stdout and not stdout:is_closing() then
			stdout:close()
		end
		if stderr and not stderr:is_closing() then
			stderr:close()
		end
		if handle and not handle:is_closing() then
			handle:close()
		end

		local full_out = table.concat(out_chunks)
		local full_err = table.concat(err_chunks)

		schedule(function()
			if code == 0 then
				cb(full_out, nil)
			else
				local tail = (full_err ~= "" and full_err or full_out):gsub("%s+$", "")
				if #tail > 800 then
					tail = tail:sub(#tail - 799)
				end
				cb(nil, ("opencode failed (%d, sig=%d): %s"):format(code, signal or 0, tail))
			end
		end)
	end)

	if not handle then
		cb(nil, ("Failed to spawn %s (is it in PATH?)"):format(cmd))
		return
	end

	stdout:read_start(function(err, data)
		if err then
			err_chunks[#err_chunks + 1] = ("[stdout read error] %s\n"):format(err)
			return
		end
		if not data then
			return
		end
		out_buf = out_buf .. data
		out_buf = flush_lines(out_buf, out_chunks, on_event)
	end)

	stderr:read_start(function(err, data)
		if err then
			err_chunks[#err_chunks + 1] = ("[stderr read error] %s\n"):format(err)
			return
		end
		if not data then
			return
		end
		err_buf = err_buf .. data
		err_buf = flush_lines(err_buf, err_chunks, nil)
	end)
end

function M.implement()
	local bufnr = api.nvim_get_current_buf()
	local filetype = bo[bufnr].filetype

	local sr, sc, er, ec = compute_target_range()
	if not sr then
		notify("No function node found and no visual selection.", log.levels.WARN)
		return
	end

	local start_id = api.nvim_buf_set_extmark(bufnr, ns, sr, sc, { right_gravity = false })
	local end_id = api.nvim_buf_set_extmark(bufnr, ns, er, ec, { right_gravity = true })

	local cur = api.nvim_win_get_cursor(0)
	local cur_row = cur[1] - 1
	local cur_col = cur[2]

	local spinner_id = api.nvim_buf_set_extmark(bufnr, ns, cur_row, cur_col, { right_gravity = false })

	local loc = mark_label(bufnr, start_id)

	local spinner_timer = start_spinner(bufnr, spinner_id, function()
		return "garbuliya: generating… (" .. loc .. ")"
	end)

	local progress = nil
	if M.config.show_fidget then
		progress = fidget_progress("garbuliya", ("generating… (%s)"):format(loc))
	end

	local orig = buf_text(bufnr, sr, sc, er, ec)
	if orig:gsub("%s+", "") == "" then
		notify("Selected region is empty.", log.levels.WARN)
		stop_spinner(bufnr, spinner_id, spinner_timer)
		if progress then
			progress:cancel()
		end
		clear_mark(bufnr, start_id)
		clear_mark(bufnr, end_id)
		clear_mark(bufnr, spinner_id)
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
- Do NOT run any tools/commands. Output only code.

Quality gate (do not output):
- Sanity-check correctness on edge cases.
- Verify time and auxiliary space complexity.
]],
		"=== REGION START ===",
		orig,
		"=== REGION END ===",
	}, "\n")

	local on_event = function(line) end

	local callback = function(stdout, err)
		schedule(function()
			local function cleanup(kind)
				stop_spinner(bufnr, spinner_id, spinner_timer)
				update_mark(bufnr, spinner_id, { virt_text = nil })
				clear_mark(bufnr, spinner_id)

				if progress then
					if kind == "cancel" then
						progress:cancel()
					elseif kind == "finish" then
						progress:finish({ message = ("Done (%s)"):format(loc) })
					end
				end

				clear_mark(bufnr, start_id)
				clear_mark(bufnr, end_id)
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
				notify("Target region became invalid; not applying.", log.levels.WARN)
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
	end

	run_llm_streaming(prompt, on_event, callback)
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	api.nvim_create_user_command("GarbuliyaImplement", function()
		M.implement()
	end, {})
end

return M
