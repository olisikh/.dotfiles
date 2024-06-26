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

return M
