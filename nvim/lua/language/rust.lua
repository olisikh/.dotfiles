local nmap = require('helpers').nmap

local mason_registry = require('mason-registry')
local dap = require('dap')

-- Setup rust and debugging
local codelldb_root = mason_registry.get_package('codelldb'):get_install_path() .. '/extension/'
local codelldb_path = codelldb_root .. 'adapter/codelldb'
local liblldb_path = codelldb_root .. 'lldb/lib/liblldb.dylib'

local M = {}

M.setup = function(capabilities, attach_lsp)
  local rt = require('rust-tools')
  rt.setup({
    server = {
      on_attach = function(client, bufnr)
        attach_lsp(client, bufnr)

        nmap('<leader>ch', rt.hover_actions.hover_actions, {
          desc = 'rust-tools: hover actions',
          buffer = bufnr,
          noremap = true,
        })
        nmap('<leader>dR', rt.runnables.runnables, {
          desc = 'rust-tools: run runnable',
          buffer = bufnr,
          noremap = true,
        })
        nmap('<leader>dd', rt.debuggables.debuggables, {
          desc = 'rust-tools: run debug',
          buffer = bufnr,
          noremap = true,
        })

        dap.configurations.rust = {
          {
            name = "Launch",
            type = 'rt_lldb',
            request = 'launch',
            program = "${workspaceFolder}/target/debug/${workspaceFolderBasename}",
            cwd = '${workspaceFolder}',
            stopOnEntry = false,
            args = {},
          },
          {
            name = 'Launch (by name)',
            type = 'rt_lldb',
            request = 'launch',
            program = function()
              local input = vim.fn.input('Path to runnable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
              if (input == nil or input == '') then
                return
              end
              return input
            end,
            cwd = '${workspaceFolder}',
            stopOnEntry = false,
            args = {},
          },
        }
      end,
    },
    capabilities = capabilities,
    dap = {
      adapter = require('rust-tools.dap').get_codelldb_adapter(codelldb_path, liblldb_path),
    },
    tools = {
      hover_actions = {
        auto_focus = true,
      },
      inlay_hints = {
        -- automatically set inlay hints (type hints)
        -- default: true
        auto = true,

        -- Only show inlay hints for the current line
        only_current_line = false,

        -- whether to show parameter hints with the inlay hints or not
        -- default: true
        show_parameter_hints = true,

        -- prefix for parameter hints
        -- default: "<-"
        parameter_hints_prefix = "<- ",

        -- prefix for all the other hints (type, chaining)
        -- default: "=>"
        other_hints_prefix = "=> ",

        -- whether to align to the length of the longest line in the file
        max_len_align = false,

        -- padding from the left if max_len_align is true
        max_len_align_padding = 1,

        -- whether to align to the extreme right or not
        right_align = false,

        -- padding from the right if right_align is true
        right_align_padding = 7,

        -- The color of the hints
        highlight = "Comment",
      },
    },
  })
end

return M
