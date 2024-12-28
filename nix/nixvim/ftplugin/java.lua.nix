{ pkgs, ... }:
# lua
''
  local jdtls = require('jdtls')

  local java_lsp_path = "${pkgs.jdt-language-server}"
  local java_dap_path = "${pkgs.vscode-extensions.vscjava.vscode-java-debug}"
  local java_test_path = "${pkgs.vscode-extensions.vscjava.vscode-java-test}"

  local bundles = {
    vim.fn.glob(java_dap_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar', true),
  }
  vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path .. '/extension/server/*.jar', true), '\n'))

  -- NOTE: Decrease the amount of files to improve speed(Experimental).
  -- INFO: It's annoying to edit the version again and again.
  local equinox_path = vim.split(vim.fn.glob(java_lsp_path .. '/plugins/*jar'), '\n')
  local equinox_launcher = ""

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
      'java',
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
      '-jar',
      equinox_launcher,
      '-configuration',
      java_lsp_path .. '/config_' .. OS_NAME,
      '-data',
      workspace_dir,
    },

    -- on_attach = function(client, bufnr)
    --   require('user.lsp_utils').default_attach(client, bufnr)
    -- end,
    -- capabilities = require('user.lsp_utils').capabilities,
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
      extendedClientCapabilities = jdtls.extendedClientCapabilities,
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


  -- NOTE: move to keymaps?
  -- nmap('<leader>jv', function()
  -- jdtls.extract_variable()
  -- end, { desc = 'jdtls: extract [v]ariable' })
  --
  -- nmap('<leader>jm', function()
  --   jdtls.extract_method()
  -- end, { desc = 'jdtls: extract [m]ethod' })
  --
  -- nmap('<leader>jc', function()
  --   jdtls.extract_constant()
  -- end, { desc = 'jdtls: extract [c]onstant' })
  --
  -- nmap('<leader>jt', function()
  --   jdtls.pick_test()
  -- end, { desc = 'jdtls: run [t]est' })
  --
  -- nmap('<leader>co', function()
  --   jdtls.organize_imports()
  -- end, { desc = 'jdtls: [o]rganize imports' })

  jdtls.start_or_attach(config)
''
