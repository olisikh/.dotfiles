-- ============================================================================
-- Garbuliya - Utility Functions
-- ============================================================================

local M = {}

-- ============================================================================
-- Text Processing
-- ============================================================================

--- Split a string into lines, normalizing line endings
function M.split_lines(s)
	local out = {}
	s = (s or ""):gsub("\r\n", "\n")
	for line in (s .. "\n"):gmatch("(.-)\n") do
		out[#out + 1] = line
	end
	return out
end

--- Strip markdown code fences from a string
function M.strip_fences(s)
	return (s or ""):gsub("^%s*```[%w_-]*%s*\n", ""):gsub("\n%s*```%s*$", "")
end

--- Check if string is empty (only whitespace)
function M.is_empty_text(text)
	return text:gsub("%s+", "") == ""
end

-- ============================================================================
-- Validation & Checks
-- ============================================================================

--- Validate that marks are still valid and in correct order
-- @param bufnr buffer number
-- @param ns namespace ID
-- @param start_id start mark ID
-- @param end_id end mark ID
-- @return start_row, start_col, end_row, end_col (0-indexed) or nil, error message
function M.validate_marks(bufnr, ns, start_id, end_id)
	local api = vim.api
	local s = api.nvim_buf_get_extmark_by_id(bufnr, ns, start_id, {})
	local e = api.nvim_buf_get_extmark_by_id(bufnr, ns, end_id, {})

	if not s or not s[1] or not e or not e[1] then
		return nil, "Target region anchor disappeared"
	end

	local sr, sc = s[1], s[2]
	local er, ec = e[1], e[2]
	if (er < sr) or (er == sr and ec < sc) then
		return nil, "Target region became invalid"
	end

	return sr, sc, er, ec
end

return M
