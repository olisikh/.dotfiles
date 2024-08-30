local mason_registry = require('mason-registry')

local jdtls_path = mason_registry.get_package('jdtls'):get_install_path()
local jdtls_bin = jdtls_path .. '/bin/jdtls'

local config = {
  cmd = { jdtls_bin },
  root_dir = vim.fs.dirname(vim.fs.find({ 'gradlew', '.git', 'mvnw' }, { upward = true })[1]),
}

require('jdtls').start_or_attach(config)
