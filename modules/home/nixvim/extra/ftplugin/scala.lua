local metals = require('metals')
local metals_tvp = require('metals.tvp')
local metals_config = metals.bare_config()

local dap = require('dap')
local map = vim.keymap.set

metals_config.tvp = {
  icons = {
    enabled = true,
  },
}
metals_config.settings = {
  defaultBspToBuildTool = true, -- use BSP, bloop sucks
  useGlobalExecutable = true,
  autoImportBuild = 'on',
  showImplicitArguments = true,
  enableSemanticHighlighting = false, -- fix highlight issues
  showImplicitConversionsAndClasses = true,
  superMethodLensesEnabled = true,
  showInferredType = true,
  excludedPackages = {
    'akka.actor.typed.javadsl',
    'com.github.swagger.akka.javadsl',
    'akka.stream.javadsl',
    'akka.http.javadsl',
  },
  inlayHints = {
    hintsInPatternMatch = { enable = true },
    implicitArguments = { enable = true },
    implicitConversions = { enable = true },
    inferredTypes = { enable = true },
    typeParameters = { enable = true },
  },
}
metals_config.init_options = {
  statusBarProvider = 'off',
}
metals_config.capabilities = require('blink.cmp').get_lsp_capabilities()
metals_config.on_attach = function(client, bufnr)
  -- Metals specific mappings
  map('v', '<leader>ctr', function() metals.type_of_range() end,
    { desc = 'metals: see type of range' })
  map('n', '<leader>chw', function() metals.hover_worksheet({ border = 'single' }) end,
    { desc = 'metals: hover worksheet' })
  map('n', '<leader>ctv', function() metals_tvp.toggle_tree_view() end,
    { desc = 'metals: toggle tree view' })
  map('n', '<leader>ctR', function() metals_tvp.reveal_in_tree() end,
    { desc = 'metals: tree reveal' })
  map('n', '<leader>cts', function() metals.toggle_setting('showImplicitArguments') end,
    { desc = 'metals: show implicit args' })
  map('n', '<leader>cmc', function() require('telescope').extensions.metals.commands() end,
    { desc = 'metals: open commands' })
  map('n', '<leader>csf', function() metals.run_scalafix() end,
    { desc = 'metals: scalafix' })
  map('n', '<leader>co', function() metals.organize_imports() end,
    { desc = 'metals: [o]rganise imports' })

  -- nvim-dap
  dap.configurations.scala = {
    {
      type = 'scala',
      request = 'launch',
      name = 'Run or test',
      metals = {
        runType = 'runOrTestFile',
      },
    },
    {
      type = 'scala',
      request = 'launch',
      name = 'Run or test (+args)',
      metals = {
        runType = 'runOrTestFile',
        args = function()
          local args_string = vim.fn.input('Arguments: ')
          return vim.split(args_string, ' +')
        end,
      },
    },
    {
      type = 'scala',
      request = 'launch',
      name = 'Test',
      metals = {
        runType = 'testTarget',
      },
    },
  }

  dap.listeners.after['event_terminated']['nvim-metals'] = function(_, _)
    dap.repl.open()
  end
  metals.setup_dap()
end

metals.initialize_or_attach(metals_config)
