-- ============================================================================
-- Garbuliya - Main Plugin Module
-- ============================================================================
-- LLM-powered code implementation plugin
-- Orchestrates all submodules to provide the main functionality

local api = vim.api
local bo = vim.bo
local log = vim.log
local schedule = vim.schedule

-- Import submodules
local utils = require("garbuliya.utils")
local ui = require("garbuliya.ui")
local range = require("garbuliya.range")
local llm = require("garbuliya.llm")
local prompt = require("garbuliya.prompt")

-- Module namespace for extmarks
local NAMESPACE = "garbuliya"
local ns = api.nvim_create_namespace(NAMESPACE)

-- Main module
local M = {}

-- ============================================================================
-- Configuration
-- ============================================================================

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

-- ============================================================================
-- Utilities
-- ============================================================================

--- Notify user with optional level
local function notify(msg, level)
	if not M.config.notify then
		return
	end
	schedule(function()
		vim.notify(msg, level or log.levels.INFO, { title = NAMESPACE })
	end)
end

--- Cleanup UI elements after operation
local function cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, kind)
	ui.stop_spinner(bufnr, ns, spinner_id, spinner_timer)
	ui.update_mark(bufnr, ns, spinner_id, { virt_text = nil })
	ui.clear_mark(bufnr, ns, spinner_id)

	if progress then
		if kind == "cancel" then
			progress:cancel()
		elseif kind == "finish" then
			local loc = ui.mark_label(bufnr, ns, start_id)
			progress:finish({ message = ("Done (%s)"):format(loc) })
		end
	end

	ui.clear_mark(bufnr, ns, start_id)
	ui.clear_mark(bufnr, ns, end_id)
end

-- ============================================================================
-- Main Implementation
-- ============================================================================

--- Main entry point: implement code in selected region or function
function M.implement()
	local bufnr = api.nvim_get_current_buf()
	local filetype = bo[bufnr].filetype

	-- Find target code range
	local sr, sc, er, ec = range.compute_target_range()
	if not sr then
		notify("No function node found and no visual selection.", log.levels.WARN)
		return
	end

	-- Set up extmarks to track the region during edits
	local start_id = api.nvim_buf_set_extmark(bufnr, ns, sr, sc, { right_gravity = false })
	local end_id = api.nvim_buf_set_extmark(bufnr, ns, er, ec, { right_gravity = true })

	-- Create spinner at cursor position
	local cur = api.nvim_win_get_cursor(0)
	local cur_row = cur[1] - 1
	local cur_col = cur[2]
	local spinner_id = api.nvim_buf_set_extmark(bufnr, ns, cur_row, cur_col, { right_gravity = false })

	local loc = ui.mark_label(bufnr, ns, start_id)

	-- Start visual feedback
	local spinner_timer = ui.start_spinner(bufnr, ns, spinner_id, function()
		return "garbuliya: generating… (" .. loc .. ")"
	end)

	local progress = nil
	if M.config.show_fidget then
		progress = ui.fidget_progress("garbuliya", ("generating… (%s)"):format(loc))
	end

	-- Get original code and validate
	local orig = range.get_buf_text(bufnr, sr, sc, er, ec)
	if utils.is_empty_text(orig) then
		notify("Selected region is empty.", log.levels.WARN)
		cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, "cancel")
		return
	end

	-- Build prompt for LLM
	local llm_prompt = prompt.build_implementation_prompt(filetype, orig)

	-- Callback invoked when LLM finishes
	local callback = function(stdout, err)
		schedule(function()
			-- Handle LLM errors
			if err then
				notify(err, log.levels.ERROR)
				cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, "cancel")
				return
			end

			-- Parse response
			local code, perr = llm.extract_code_from_response(stdout)
			if perr then
				notify(perr, log.levels.ERROR)
				cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, "cancel")
				return
			end

			-- Validate extracted code
			if not code or utils.is_empty_text(code) then
				notify("LLM returned empty output.", log.levels.ERROR)
				cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, "cancel")
				return
			end

			-- Verify buffer still exists
			if not api.nvim_buf_is_valid(bufnr) then
				notify("Buffer no longer valid; not applying.", log.levels.WARN)
				cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, "cancel")
				return
			end

			-- Re-validate region marks
			local sr2, sc2, er2, ec2 = utils.validate_marks(bufnr, ns, start_id, end_id)
			if not sr2 then
				notify(sc2 .. "; not applying.", log.levels.WARN)
				cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, "cancel")
				return
			end

			-- Update progress before applying
			if progress then
				progress:report({ message = ("Applying… (%s)"):format(loc) })
			end

			-- Apply the implementation
			api.nvim_buf_set_text(bufnr, sr2, sc2, er2, ec2, utils.split_lines(code))
			notify("Applied implementation.")
			cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, "finish")
		end)
	end

	-- Kick off async LLM call
	llm.run_llm_streaming(M.config, llm_prompt, function(line) end, callback)
end

-- ============================================================================
-- Module Setup
-- ============================================================================

--- Initialize the plugin with optional configuration
-- @param opts table with optional config overrides:
--   - opencode_cmd: command to run (default: "opencode")
--   - model: model identifier (default: "opencode/gpt-5.1-codex-mini")
--   - format: output format (default: "json")
--   - notify: show notifications (default: true)
--   - show_fidget: show fidget progress (default: false)
--   - system_prompt: custom system prompt
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	api.nvim_create_user_command("GarbuliyaImplement", function()
		M.implement()
	end, {})
end

return M
