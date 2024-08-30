local M = {}

M.map = function(mode, lhs, rhs, opts)
  local _opts = { noremap = true }
  if opts then
    _opts = vim.tbl_extend('force', _opts, opts)
  end
  vim.keymap.set(mode, lhs, rhs, _opts)
end

M.nmap = function(lhs, rhs, opts)
  M.map('n', lhs, rhs, opts)
end

M.vmap = function(lhs, rhs, opts)
  M.map('v', lhs, rhs, opts)
end

M.list_merge = function(...)
  if select('#', ...) < 2 then
    error(
      'wrong number of arguments (given '
        .. tostring(1 + select('#', ...))
        .. ', expected at least 2)'
    )
  end

  local result = {}
  for i = 1, select('#', ...) do
    local list = select(i, ...)
    for _, v in ipairs(list) do
      table.insert(result, v)
    end
  end

  return result
end

return M
