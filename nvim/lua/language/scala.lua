local nmap = require('helpers').nmap
local map = require('helpers').map
local dap = require('dap')

local M = {}

M.setup = function(capabilities, attach_lsp)
  local metals_group = vim.api.nvim_create_augroup('metals', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'scala', 'sbt', 'java' },
    group = metals_group,
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
        showImplicitArguments = true,
        showImplicitConversionsAndClasses = true,
        showInferredType = true,
        excludedPackages = {
          'akka.actor.typed.javadsl',
          'com.github.swagger.akka.javadsl',
          'akka.stream.javadsl',
          'akka.http.javadsl',
        },
      }
      metals_config.init_options = {
        statusBarProvider = 'on',
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
        nmap('<leader>mo', metals.organize_imports, { desc = 'metals: organize imports' })
        nmap('<leader>mi', metals.import_build, { desc = 'metals: import build' })
        nmap('<leader>mc', require('telescope').extensions.metals.commands, { desc = 'metals: open commands' })

        attach_lsp(client, bufnr)

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
