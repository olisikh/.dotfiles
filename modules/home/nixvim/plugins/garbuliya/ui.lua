-- ============================================================================
-- Garbuliya - UI Management (Extmarks, Spinners)
-- ============================================================================

local M = {}

local api = vim.api
local fn = vim.fn
local schedule = vim.schedule
local uv = vim.loop

-- Private constants
local SPINNER_FRAMES = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local SPINNER_INTERVAL_MS = 120

-- ============================================================================
-- Extmark Management
-- ============================================================================

--- Get display label for a mark (filename and position)
function M.mark_label(bufnr, ns, mark_id)
	local name = api.nvim_buf_get_name(bufnr)
	name = (name == "" and "[No Name]") or fn.fnamemodify(name, ":t")

	local pos = api.nvim_buf_get_extmark_by_id(bufnr, ns, mark_id, {})
	if not pos or not pos[1] then
		return name
	end

	return ("%s:%d:%d"):format(name, pos[1] + 1, pos[2] + 1)
end

--- Update an extmark's properties by ID
function M.update_mark(bufnr, ns, mark_id, opts)
	local pos = api.nvim_buf_get_extmark_by_id(bufnr, ns, mark_id, {})
	if not pos or not pos[1] then
		return false
	end
	api.nvim_buf_set_extmark(bufnr, ns, pos[1], pos[2], vim.tbl_extend("force", { id = mark_id }, opts or {}))
	return true
end

--- Remove an extmark by ID
function M.clear_mark(bufnr, ns, mark_id)
	pcall(api.nvim_buf_del_extmark, bufnr, ns, mark_id)
end

--- Clear all virtual text from garbuliya namespace in a buffer
-- Ensures no orphaned spinners or text remain
function M.clear_all_virt_text(bufnr, ns)
	if not api.nvim_buf_is_valid(bufnr) then
		return
	end

	-- Get all extmarks in the namespace
	local marks = api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true })
	for _, mark in ipairs(marks) do
		local mark_id = mark[1]
		-- Remove virtual text from each mark
		pcall(api.nvim_buf_set_extmark, bufnr, ns, mark[2], mark[3], {
			id = mark_id,
			virt_text = nil,
		})
	end
end

-- ============================================================================
-- Spinner Animation
-- ============================================================================

--- Start an animated spinner at a mark position
-- @param bufnr buffer number
-- @param ns namespace ID
-- @param mark_id extmark ID to animate
-- @param label_fn optional function to get dynamic label text
-- @return timer object (must be stopped/closed by caller)
function M.start_spinner(bufnr, ns, mark_id, label_fn)
	local i = 1
	local timer = uv.new_timer()

	timer:start(0, SPINNER_INTERVAL_MS, function()
		schedule(function()
			if not api.nvim_buf_is_valid(bufnr) then
				timer:stop()
				timer:close()
				return
			end

			local icon = SPINNER_FRAMES[i]
			i = (i % #SPINNER_FRAMES) + 1

			local label = label_fn and label_fn() or ""
			local msg = (label ~= "" and (" " .. label) or "")

			local ok = M.update_mark(bufnr, ns, mark_id, {
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

--- Stop and clean up a spinner animation
function M.stop_spinner(bufnr, ns, mark_id, timer)
	if timer then
		pcall(function()
			timer:stop()
			timer:close()
		end)
	end
	schedule(function()
		if api.nvim_buf_is_valid(bufnr) then
			M.update_mark(bufnr, ns, mark_id, { virt_text = nil })
		end
	end)
end

-- ============================================================================
-- Fidget Integration (Optional)
-- ============================================================================

--- Try to get fidget progress handle (safe if fidget not installed)
function M.fidget_progress(title, message)
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

return M
