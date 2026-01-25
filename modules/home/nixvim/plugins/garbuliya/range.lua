-- ============================================================================
-- Garbuliya - Range Detection
-- ============================================================================

local M = {}

local api = vim.api
local fn = vim.fn

-- Constants
local MAX_FUNCTION_LINES = 4000

-- ============================================================================
-- Visual Selection
-- ============================================================================

--- Get visual selection range if in visual mode
-- @return start_row, start_col, end_row, end_col (0-indexed) or nil
function M.get_visual_range()
	local mode = fn.mode()
	if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
		return nil
	end
	local srow, scol = unpack(api.nvim_buf_get_mark(0, "<"))
	local erow, ecol = unpack(api.nvim_buf_get_mark(0, ">"))
	return srow - 1, scol, erow - 1, ecol
end

-- ============================================================================
-- TreeSitter Function Detection
-- ============================================================================

--- Find the nearest enclosing function/method using TreeSitter
-- @return start_row, start_col, end_row, end_col (0-indexed) or nil
function M.ts_find_nearest_function_range()
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
			-- Avoid extremely large functions
			if (er - sr) <= MAX_FUNCTION_LINES then
				return sr, sc, er, ec
			end
		end
		node = node:parent()
	end
	return nil
end

-- ============================================================================
-- Range Computation
-- ============================================================================

--- Compute target range: tries TreeSitter first, then falls back to visual selection
-- @return start_row, start_col, end_row, end_col (0-indexed) or nil
function M.compute_target_range()
	local sr, sc, er, ec = M.ts_find_nearest_function_range()
	if sr then
		return sr, sc, er, ec
	end

	local vr = { M.get_visual_range() }
	if #vr == 4 then
		return vr[1], vr[2], vr[3], vr[4]
	end

	return nil
end

--- Get text from buffer in a range
function M.get_buf_text(bufnr, sr, sc, er, ec)
	local lines = api.nvim_buf_get_text(bufnr, sr, sc, er, ec, {})
	return table.concat(lines, "\n")
end

return M
