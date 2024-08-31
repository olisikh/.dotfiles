local nmap = require('user.utils').nmap

local mason_registry = require('mason-registry')

local java_lsp_path = mason_registry.get_package('jdtls'):get_install_path()
local java_dap_path = mason_registry.get_package('java-debug-adapter'):get_install_path()
local java_test_path = mason_registry.get_package('java-test'):get_install_path()

local bundles = {
  vim.fn.glob(java_dap_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar', true),
}
vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path .. '/extension/server/*.jar', true), '\n'))

-- NOTE: Decrease the amount of files to improve speed(Experimental).
-- INFO: It's annoying to edit the version again and again.
local equinox_path = vim.split(vim.fn.glob(java_lsp_path .. '/plugins/*jar'), '\n')
local equinox_launcher = ''

for _, file in pairs(equinox_path) do
  if file:match('launcher_') then
    equinox_launcher = file
    break
  end
end

WORKSPACE_PATH = vim.fn.stdpath('data') .. '/workspace/'
if vim.fn.has('mac') == 1 then
  OS_NAME = 'mac'
elseif vim.fn.has('unix') == 1 then
  OS_NAME = 'linux'
elseif vim.fn.has('win32') == 1 then
  OS_NAME = 'win'
else
  vim.notify('Unsupported OS', vim.log.levels.WARN, { title = 'Jdtls' })
end

local root_markers = { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' }
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = WORKSPACE_PATH .. project_name

local config = {
  cmd = {
    -- 💀
    'java', -- or '/path/to/java17_or_newer/bin/java'
    -- depends on if `java` is in your $PATH env variable and if it points to the right version.

    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-javaagent:' .. java_lsp_path .. '/lombok.jar',
    '-Xms1g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',
    -- 💀
    '-jar',
    equinox_launcher,
    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                                       ^^^^^^^^^^^^^^
    -- Must point to the                                                     Change this to
    -- eclipse.jdt.ls installation                                           the actual version
    -- 💀
    '-configuration',
    java_lsp_path .. '/config_' .. OS_NAME,
    -- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^        ^^^^^^
    -- Must point to the                      Change to one of `linux`, `win` or `mac`
    -- eclipse.jdt.ls installation            Depending on your system.

    '-data',
    workspace_dir,
  },

  on_attach = require('user.lsp_utils').on_attach,
  capabilities = require('user.lsp_utils').capabilities,
  -- 💀
  -- This is the default if not provided, you can remove it. Or adjust as needed.
  -- One dedicated LSP server & client will be started per unique root_dir
  root_dir = require('jdtls.setup').find_root(root_markers),
  init_options = {
    bundles = bundles,
  },
  settings = {
    eclipse = {
      downloadSources = true,
    },
    maven = {
      downloadSources = true,
    },
    implementationsCodeLens = {
      enabled = true,
    },
    referencesCodeLens = {
      enabled = true,
    },
    references = {
      includeDecompiledSources = true,
    },

    signatureHelp = { enabled = true },
    extendedClientCapabilities = require('jdtls').extendedClientCapabilities,
    sources = {
      organizeImports = {
        starThreshold = 9999,
        staticStarThreshold = 9999,
      },
    },
  },
  flags = {
    allow_incremental_sync = true,
  },
}

local bufnr = vim.api.nvim_get_current_buf()

nmap("<leader>co", ":lua require'jdtls'.organize_imports()<cr>", { buffer = bufnr, desc = "lsp: [o]rganize imports" })
nmap("<leader>cv", ":lua require'jdtls'.extract_variable()<cr>", { buffer = bufnr, desc = "lsp: extract [v]ariable" })
nmap("<leader>cm", ":lua require'jdtls'.extract_method()<cr>", { buffer = bufnr, desc = "lsp: extract [m]ethod"})
nmap("<leader>cc", ":lua require'jdtls'.extract_constant()<cr>", { buffer = bufnr, desc = "lsp: extract [c]onstant"})

require('jdtls').start_or_attach(config)
