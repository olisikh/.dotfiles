-- ============================================================================
-- Garbuliya - LLM Streaming & Response Parsing
-- ============================================================================

local M = {}

local json = vim.json
local schedule = vim.schedule
local uv = vim.loop

local utils = require("garbuliya.utils")

-- Constants
local ERROR_TAIL_MAX_CHARS = 800

-- ============================================================================
-- Response Parsing
-- ============================================================================

--- Extract text content from streaming JSON response
-- Handles multiple response formats (streaming, choices, parts, etc.)
-- @param raw_text JSON lines from opencode stdout
-- @return code string or nil, error message or nil
function M.extract_code_from_response(raw_text)
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

				-- Check for API errors
				if obj.error then
					local msg = obj.error.message or vim.inspect(obj.error)
					return nil, "opencode error: " .. tostring(msg)
				end

				local et = obj.type
				local part = obj.part

				-- Try multiple response formats to be resilient
				if et == "text" and type(part) == "table" and type(part.text) == "string" and part.text ~= "" then
					acc[#acc + 1] = part.text
				else
					-- Streaming format: choices[0].delta.content
					local choice = obj.choices and obj.choices[1]
					local delta = choice and choice.delta and choice.delta.content
					if type(delta) == "string" and delta ~= "" then
						acc[#acc + 1] = delta
					end

					-- Streaming format: choices[0].message.content
					local msg = choice and choice.message and choice.message.content
					if type(msg) == "string" and msg ~= "" then
						acc[#acc + 1] = msg
					end

					-- Top-level text field
					if type(obj.text) == "string" and obj.text ~= "" then
						acc[#acc + 1] = obj.text
					end

					-- Top-level content field
					if type(obj.content) == "string" and obj.content ~= "" then
						acc[#acc + 1] = obj.content
					end

					-- Part content field
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
	content = utils.strip_fences(content)

	if utils.is_empty_text(content) then
		return nil, "Could not extract text from opencode events. First bytes: " .. raw_text:sub(1, 300)
	end

	return content, nil
end

-- ============================================================================
-- LLM Streaming
-- ============================================================================

--- Stream output from opencode command and invoke callbacks
-- Combines system prompt with user prompt and handles streaming response
-- @param config table with opencode_cmd, format, model, system_prompt
-- @param prompt user's request prompt
-- @param on_event callback for each JSON line (optional)
-- @param cb completion callback with (stdout, err) signature
function M.run_llm_streaming(config, prompt, on_event, cb)
	local message = table.concat({ config.system_prompt, "", prompt }, "\n")

	local cmd = config.opencode_cmd or "opencode"
	local args = {
		"run",
		"--format",
		(config.format or "json"),
		"--model",
		config.model,
		message,
	}

	local stdout = uv.new_pipe(false)
	local stderr = uv.new_pipe(false)

	local out_chunks = {}
	local err_chunks = {}
	local out_buf = ""
	local err_buf = ""

	--- Extract complete lines from buffer and optionally emit them
	-- Returns remaining incomplete line in buffer
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

	--- Handle process completion and collect output
	local function on_exit(code, signal)
		-- Stop reading from pipes
		if stdout and not stdout:is_closing() then
			stdout:read_stop()
		end
		if stderr and not stderr:is_closing() then
			stderr:read_stop()
		end

		-- Flush remaining buffers
		if out_buf ~= "" then
			out_chunks[#out_chunks + 1] = out_buf
			out_buf = ""
		end
		if err_buf ~= "" then
			err_chunks[#err_chunks + 1] = err_buf
			err_buf = ""
		end

		-- Close pipes and handle
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
				-- Use stderr if available, otherwise stdout
				local tail = (full_err ~= "" and full_err or full_out):gsub("%s+$", "")
				-- Truncate long error messages for readability
				if #tail > ERROR_TAIL_MAX_CHARS then
					tail = tail:sub(#tail - (ERROR_TAIL_MAX_CHARS - 1))
				end
				cb(nil, ("opencode failed (%d, sig=%d): %s"):format(code, signal or 0, tail))
			end
		end)
	end

	-- Spawn the process
	local handle, pid
	handle, pid = uv.spawn(cmd, { args = args, stdio = { nil, stdout, stderr } }, on_exit)

	if not handle then
		cb(nil, ("Failed to spawn %s (is it in PATH?)"):format(cmd))
		return
	end

	-- Handle stdout data
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

	-- Handle stderr data
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

return M
