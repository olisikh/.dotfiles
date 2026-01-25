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
	notify = true,
	show_fidget = true,
	system_prompt = [[
You are an expert software engineer focused on correctness, performance, and simplicity.

You write concise, readable, maintainable, performant, production-quality code.
You do not explain your reasoning unless explicitly asked.
You strictly follow instructions and constraints.
]],
}

-- ============================================================================
-- State Management
-- ============================================================================

-- Track all active operations (allow multiple)
-- Key: operation_id (generated), Value: {bufnr, process_id, spinner_id, etc.}
local active_operations = {}
local next_operation_id = 1

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
local function cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, kind, cost, op_id)
	-- Stop spinner first
	ui.stop_spinner(bufnr, ns, spinner_id, spinner_timer)

	-- Clear all virtual text in the namespace to ensure nothing is orphaned
	ui.clear_all_virt_text(bufnr, ns)

	-- Clear individual marks
	ui.clear_mark(bufnr, ns, spinner_id)
	ui.clear_mark(bufnr, ns, start_id)
	ui.clear_mark(bufnr, ns, end_id)

	-- Handle progress based on completion type
	if progress then
		if kind == "cancel" then
			pcall(function()
				progress:cancel()
			end)
		elseif kind == "finish" then
			pcall(function()
				local loc = ui.mark_label(bufnr, ns, start_id)
				local msg = ("Done (%s)"):format(loc)
				-- Append cost info if available
				if cost and type(cost) == "table" then
					local cost_value = cost.cost or cost.total_cost or cost.input_cost or cost.output_cost
					if cost_value then
						if type(cost_value) == "number" then
							msg = msg .. (" - Cost: $%.6f"):format(cost_value)
						else
							msg = msg .. (" - Cost: " .. tostring(cost_value))
						end
					end
					-- Add tokens if available
					if cost.tokens and type(cost.tokens) == "table" then
						local input = cost.tokens.input or 0
						local output = cost.tokens.output or 0
						msg = msg .. (", Tokens: %d→%d"):format(input, output)
					end
				end
				progress:report({ message = msg })
				-- Delay finish by 5 seconds so the message stays visible
				vim.defer_fn(function()
					progress:finish()
				end, 5000)
			end)
		end
	end

	-- Remove from active operations
	if op_id then
		active_operations[op_id] = nil
	end
end

--- Cancel the most recent active operation
local function cancel_operation()
	if not next(active_operations) then
		notify("No active generation to cancel.", log.levels.WARN)
		return
	end

	-- Find the most recent operation (highest operation_id)
	local latest_op_id = nil
	for op_id in pairs(active_operations) do
		if not latest_op_id or op_id > latest_op_id then
			latest_op_id = op_id
		end
	end

	if not latest_op_id then
		return
	end

	local op = active_operations[latest_op_id]
	notify(("Cancelling generation %d..."):format(latest_op_id))

	-- Kill the LLM process
	if op.process_id then
		llm.cancel_all_processes()
	end

	-- Cleanup UI (safely, buffer might be invalid)
	local bufnr = op.bufnr
	if bufnr and api.nvim_buf_is_valid(bufnr) then
		cleanup_operation(
			bufnr,
			op.spinner_id,
			op.spinner_timer,
			op.progress,
			op.start_id,
			op.end_id,
			"cancel"
		)
		-- Also ensure all virt text is cleared
		ui.clear_all_virt_text(bufnr, ns)
	end

	-- Remove from active operations
	active_operations[latest_op_id] = nil

	notify("Generation cancelled.")
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

	-- Generate new operation ID
	local op_id = next_operation_id
	next_operation_id = next_operation_id + 1

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
		return ("garbuliya [%d]: generating… (%s)"):format(op_id, loc)
	end)

	local progress = nil
	if M.config.show_fidget then
		progress = ui.fidget_progress("garbuliya", ("generating… (%s)"):format(loc))
	end

	-- Get original code and validate
	local orig = range.get_buf_text(bufnr, sr, sc, er, ec)
	if utils.is_empty_text(orig) then
		notify("Selected region is empty.", log.levels.WARN)
		cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, "cancel", nil, op_id)
		return
	end

	-- Store operation info for tracking
	active_operations[op_id] = {
		bufnr = bufnr,
		progress = progress,
		spinner_timer = spinner_timer,
		spinner_id = spinner_id,
		start_id = start_id,
		end_id = end_id,
		process_id = nil,  -- Will be set when LLM starts
	}

	notify(("Generation %d started..."):format(op_id))

	-- Build prompt for LLM
	local llm_prompt = prompt.build_implementation_prompt(filetype, orig)

	-- Callback invoked when LLM finishes
	local callback = function(stdout, err)
		schedule(function()
			-- Handle LLM errors
			if err then
				notify(("Generation %d error: %s"):format(op_id, err), log.levels.ERROR)
				cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, "cancel", nil, op_id)
				return
			end

			-- Parse response and extract cost
			local code, perr = llm.extract_code_from_response(stdout)
			if perr then
				notify(("Generation %d: %s"):format(op_id, perr), log.levels.ERROR)
				cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, "cancel", nil, op_id)
				return
			end

			local cost = llm.extract_cost_from_response(stdout)

			-- Validate extracted code
			if not code or utils.is_empty_text(code) then
				notify(("Generation %d: LLM returned empty output."):format(op_id), log.levels.ERROR)
				cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, "cancel", nil, op_id)
				return
			end

			-- Verify buffer still exists
			if not api.nvim_buf_is_valid(bufnr) then
				notify(("Generation %d: Buffer no longer valid."):format(op_id), log.levels.WARN)
				cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, "cancel", nil, op_id)
				return
			end

			-- Re-validate region marks
			local sr2, sc2, er2, ec2 = utils.validate_marks(bufnr, ns, start_id, end_id)
			if not sr2 then
				notify(("Generation %d: %s"):format(op_id, sc2), log.levels.WARN)
				cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, "cancel", nil, op_id)
				return
			end

			-- Update progress before applying
			if progress then
				progress:report({ message = ("Applying… (%s)"):format(loc) })
			end

			-- Apply the implementation
			api.nvim_buf_set_text(bufnr, sr2, sc2, er2, ec2, utils.split_lines(code))
			
			-- Build completion message with cost info
			local completion_msg = ("Applied generation %d"):format(op_id)
			if cost and type(cost) == "table" then
				local cost_value = cost.cost or cost.total_cost
				if cost_value then
					completion_msg = completion_msg .. (" - Cost: $%.6f"):format(cost_value)
					if cost.tokens then
						local input = cost.tokens.input or 0
						local output = cost.tokens.output or 0
						completion_msg = completion_msg .. (", Tokens: %d→%d"):format(input, output)
					end
				end
			end
			notify(completion_msg)
			cleanup_operation(bufnr, spinner_id, spinner_timer, progress, start_id, end_id, "finish", cost, op_id)
		end)
	end

	-- Kick off async LLM call and store the process ID
	local process_id = llm.run_llm_streaming(M.config, llm_prompt, function(line) end, callback)
	if active_operations[op_id] then
		active_operations[op_id].process_id = process_id
	end
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

	-- Create main Garbuliya command with subcommands
	api.nvim_create_user_command("Garbuliya", function(opts_cmd)
		local args = vim.split(opts_cmd.args, "%s+")
		local cmd = args[1]

		if cmd == "implement" then
			M.implement()
		elseif cmd == "cancel" then
			cancel_operation()
		else
			notify("Unknown command: " .. (cmd or ""), log.levels.ERROR)
		end
	end, {
		nargs = "+",
		complete = function()
			return { "implement", "cancel" }
		end,
	})
end

return M
