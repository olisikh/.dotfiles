local M = {}

M.setup = function(_)
  local dap_python = require('dap-python')
  dap_python.test_runner = 'pytest'
  dap_python.setup('python3')
end

return M
