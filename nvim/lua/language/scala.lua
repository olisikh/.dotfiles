local nmap = require('utils').nmap
local map = require('utils').map
local dap = require('dap')

local M = {}

M.setup = function(group, capabilities)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'scala', 'sbt', 'java' },
    group = group,
    callback = function()
      local metals = require('metals')
      local metals_tvp = require('metals.tvp')
      local metals_config = metals.bare_config()

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
        showImplicitConversionsAndClasses = true,
        superMethodLensesEnabled = true,
        showInferredType = true,
        excludedPackages = {
          'akka.actor.typed.javadsl',
          'com.github.swagger.akka.javadsl',
          'akka.stream.javadsl',
          'akka.http.javadsl',
        },
      }
      metals_config.init_options = {
        statusBarProvider = 'off',
      }
      metals_config.capabilities = capabilities
      metals_config.on_attach = function(client, bufnr)
        -- Metals specific mappings
        map('v', '<leader>mt', metals.type_of_range, { desc = 'metals: see type of range' })
        nmap('<leader>mw', function()
          metals.hover_worksheet({ border = 'single' })
        end, { desc = 'metals: hover worksheet' })
        nmap('<leader>mv', metals_tvp.toggle_tree_view, { desc = 'metals: toggle tree view' })
        nmap('<leader>mr', metals_tvp.reveal_in_tree, { desc = 'metals: reveal in tree' })
        nmap('<leader>mi', function()
          metals.toggle_setting('showImplicitArguments')
        end, { desc = 'metals: show implicit args' })
        nmap('<leader>mc', require('telescope').extensions.metals.commands, { desc = 'metals: open commands' })

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
    end,
  })
end

return M
