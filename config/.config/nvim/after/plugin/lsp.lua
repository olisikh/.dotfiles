local function attach_lsp(bufnr)
  local function nmap(lhs, rhs, desc)
    require('helpers').nmap(lhs, rhs, { buffer = bufnr, desc = 'lsp: ' .. desc })
  end

  nmap('<leader>cr', vim.lsp.buf.rename, '[r]ename')
  nmap('<leader>ca', vim.lsp.buf.code_action, '[c]ode [a]ction')
  nmap('<leader>cf', vim.lsp.buf.format, '[c]ode [f]ormat')

  nmap('gd', require('telescope.builtin').lsp_definitions, '[g]oto [d]efinition')
  nmap('gr', require('telescope.builtin').lsp_references, '[g]oto [r]eferences')
  nmap('gI', vim.lsp.buf.implementation, '[g]oto [i]mplementation')
  nmap('gt', vim.lsp.buf.type_definition, '[g]oto [t]ype definition')
  nmap('gD', vim.lsp.buf.declaration, '[g]oto [d]eclaration')

  nmap('<leader>ws', require('telescope.builtin').lsp_document_symbols, '[d]ocument [s]ymbols')
  nmap('<leader>wS', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[w]orkspace [s]ymbols')
  -- nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[w]orkspace [a]dd folder')
  -- nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[w]orkspace [r]emove folder')
  -- nmap('<leader>wl', function()
  --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  -- end, '[w]orkspace [l]ist folders')

  -- See `:help K` for why this keymap
  nmap('Q', vim.lsp.buf.hover, 'hover documentation')
  nmap('K', vim.lsp.buf.signature_help, 'signature documentation')

  local function fmt_code()
    vim.lsp.buf.format({ bufnr = bufnr })
  end

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', fmt_code, { desc = 'lsp: format code' })

  -- Format code before save :w
  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '<buffer>',
    callback = fmt_code,
  })
end

-- Setup neovim lua configuration, allows peek into plugins code
require('neodev').setup()

local lsp_group = vim.api.nvim_create_augroup('lsp', { clear = true })

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
capabilities.textDocument.completion.completionItem.snippetSupport = true

-- Ensure the servers above are installed
local mason_lspconfig = require('mason-lspconfig')
local mason_registry = require('mason-registry')

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
local servers = {
  dockerls = {},
  bashls = {},
  rust_analyzer = {
    cargo = {
      allFeatures = true,
    },
    checkOnSave = {
      command = 'clippy',
    },
  },
  gopls = {},
  tsserver = {},
  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
}

mason_lspconfig.setup({
  ensure_installed = vim.tbl_keys(servers),
})

mason_lspconfig.setup_handlers({
  function(server_name)
    -- LSP settings.
    --  This function gets run when an LSP connects to a particular buffer.
    local on_attach = function(_, bufnr)
      -- NOTE: Remember that lua is a real programming language, and as such it is possible
      -- to define small helper and utility functions so you don't have to repeat yourself
      -- many times.
      --
      -- In this case, we create a function that lets us more easily define local mappings specific
      -- for LSP related items. It sets the mode, buffer and description for us each time.
      attach_lsp(bufnr)
    end

    require('lspconfig')[server_name].setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = servers[server_name],
    })
  end,
})

-- [[ Scala metals ]]
-- See `:help metals`???
local metals_group = vim.api.nvim_create_augroup('metals', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'scala', 'sbt', 'java' },
  group = metals_group,
  callback = function()
    local function map(mode, lhs, rhs, opts)
      local options = { noremap = true }
      if opts then
        options = vim.tbl_extend('force', options, opts)
      end

      require('helpers').map(mode, lhs, rhs, options)
    end

    local metals = require('metals')
    local metals_config = metals.bare_config()
    metals_config = {
      tvp = {
        icons = {
          enabled = true,
        },
      },
      settings = {
        showImplicitArguments = true,
        showImplicitConversionsAndClasses = true,
        showInferredType = true,
        excludedPackages = {
          'akka.actor.typed.javadsl',
          'com.github.swagger.akka.javadsl',
          'akka.stream.javadsl',
          'akka.http.javadsl',
        },
        fallbackScalaVersion = '2.13.10',
        serverVersion = 'latest.snapshot',
      },
      init_options = {
        statusBarProvider = 'on',
      },
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        -- Metals specific mappings
        map(
          'v',
          '<leader>mt',
          [[<Esc><cmd>lua require("metals").type_of_range()<cr>]],
          { desc = 'metals: see type of range' }
        )
        map(
          'n',
          '<leader>mw',
          [[<cmd>lua require("metals").hover_worksheet({ border = "single" })<cr>]],
          { desc = 'metals: hover worksheet' }
        )
        map(
          'n',
          '<leader>mv',
          [[<cmd>lua require("metals.tvp").toggle_tree_view()<cr>]],
          { desc = 'metals: toggle tree view' }
        )
        map(
          'n',
          '<leader>mr',
          [[<cmd>lua require("metals.tvp").reveal_in_tree()<cr>]],
          { desc = 'metals: reveal in tree' }
        )
        map(
          'n',
          '<leader>mi',
          [[<cmd>lua require("metals").toggle_setting("showImplicitArguments")<cr>]],
          { desc = 'metals: show implicit args' }
        )
        map(
          'n',
          '<leader>mo',
          [[<cmd>lua require("metals").organize_imports()<cr>]],
          { desc = 'metals: organize imports' }
        )
        map('n', '<leader>mg', [[<cmd>lua require("metals").goto_location()<cr>]], { desc = 'metals: goto location' })
        map(
          'n',
          '<leader>md',
          [[<cmd>lua require("metals").implementation_location()<cr>]],
          { desc = 'metals: implementation location' }
        )
        map('n', '<leader>mi', [[<cmd>lua require("metals").import_build()<cr>]], { desc = 'metals: import build' })
        map(
          'n',
          '<leader>mc',
          [[<cmd>lua require("telescope").extensions.metals.commands()<cr>]],
          { desc = 'metals: open commands' }
        )

        attach_lsp(bufnr)

        vim.api.nvim_create_autocmd('CursorHold', {
          callback = vim.lsp.buf.document_highlight,
          buffer = bufnr,
          group = lsp_group,
        })
        vim.api.nvim_create_autocmd('CursorMoved', {
          callback = vim.lsp.buf.clear_references,
          buffer = bufnr,
          group = lsp_group,
        })
        vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
          callback = vim.lsp.codelens.refresh,
          buffer = bufnr,
          group = lsp_group,
        })
        vim.api.nvim_create_autocmd('FileType', {
          pattern = { 'dap-repl' },
          callback = function()
            require('dap.ext.autocompl').attach()
          end,
          group = lsp_group,
        })

        -- nvim-dap
        local dap = require('dap')

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
      end,
    }

    metals.initialize_or_attach(metals_config)
  end,
})

-- Setup rust and debugging
local codelldb_root = mason_registry.get_package('codelldb'):get_install_path() .. '/extension/'
local codelldb_path = codelldb_root .. 'adapter/codelldb'
local liblldb_path = codelldb_root .. 'lldb/lib/liblldb.dylib'

local rt = require('rust-tools')
rt.setup({
  server = {
    on_attach = function(_, bufnr)
      attach_lsp(bufnr)

      local nmap = require('helpers').nmap
      nmap('<leader>ch', rt.hover_actions.hover_actions, { desc = 'rt: hover actions', buffer = bufnr, noremap = true })
      nmap('<leader>cd', '<cmd>:RustDebuggables<cr>', { desc = 'rt: show debuggables', buffer = bufnr, noremap = true })

      local dap = require('dap')

      dap.configurations.rust = {
        {
          name = 'Rust debug',
          type = 'rt_lldb',
          request = 'launch',
          program = function()
            local file = vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
            if vim.fn.len(file) == 0 then
              return
            else
              return file
            end
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = true,
          showDisassembly = 'never',
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
  },
})

-- Setup javascript & typescript (mostly dap)
local js_debugger = mason_registry.get_package('js-debug-adapter'):get_install_path()
local js_group = vim.api.nvim_create_augroup('javascript', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  group = js_group,
  callback = function()
    require('dap-vscode-js').setup({
      node_path = 'node',
      debugger_path = js_debugger,
      debugger_cmd = { 'js-debug-adapter' },
      adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' }, -- which adapters to register in nvim-dap
    })

    local dap = require('dap')

    -- js and ts debug configs
    for _, language in ipairs({ 'typescript', 'javascript' }) do
      dap.configurations[language] = {
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch file',
          program = '${file}',
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
        },
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Debug Jest Tests',
          -- trace = true, -- include debugger info
          runtimeExecutable = 'node',
          runtimeArgs = {
            './node_modules/jest/bin/jest.js',
            '--runInBand',
          },
          rootPath = '${workspaceFolder}',
          cwd = '${workspaceFolder}',
          console = 'integratedTerminal',
          internalConsoleOptions = 'neverOpen',
        },
      }
    end

    -- react debug configs
    for _, language in ipairs({ 'typescriptreact', 'javascriptreact' }) do
      dap.configurations[language] = {
        {
          type = 'pwa-chrome',
          name = 'Attach - Remote Debugging',
          request = 'attach',
          program = '${file}',
          cwd = vim.fn.getcwd(),
          sourceMaps = true,
          protocol = 'inspector',
          port = 9222,
          webRoot = '${workspaceFolder}',
        },
        {
          type = 'pwa-chrome',
          name = 'Launch Chrome',
          request = 'launch',
          url = 'http://localhost:3000',
        },
      }
    end
  end,
})

-- setup lua dap
local lua_group = vim.api.nvim_create_augroup('lua', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'lua' },
  group = lua_group,
  callback = function()
    local dap = require('dap')

    dap.configurations.lua = {
      {
        type = 'nlua',
        request = 'attach',
        name = 'Attach to running Neovim instance',
      },
    }

    dap.adapters.nlua = function(callback, config)
      callback({
        type = 'server',
        host = config.host or '127.0.0.1',
        port = config.port or 8086,
      })
    end
  end,
})

local go_group = vim.api.nvim_create_augroup('go', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'go' },
  group = go_group,
  callback = function()
    local dap_go = require('dap-go')

    dap_go.setup({
      -- Additional dap configurations can be added.
      -- dap_configurations accepts a list of tables where each entry
      -- represents a dap configuration. For more details do:
      -- :help dap-configuration
      dap_configurations = {
        {
          -- Must be "go" or it will be ignored by the plugin
          type = 'go',
          name = 'Attach remote',
          mode = 'remote',
          request = 'attach',
        },
      },
      -- delve configurations
      delve = {
        -- time to wait for delve to initialize the debug session.
        -- default to 20 seconds
        initialize_timeout_sec = 20,
        -- a string that defines the port to start delve debugger.
        -- default to string "${port}" which instructs nvim-dap
        -- to start the process in a random available port
        port = '${port}',
      },
    })
  end,
})
