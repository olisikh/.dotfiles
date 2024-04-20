local helpers = require('helpers')
local nmap = helpers.nmap
local map = helpers.map
local has_value = helpers.has_value

local telescope_builtin = require('telescope.builtin')
local lsp_group = vim.api.nvim_create_augroup('lsp', { clear = true })

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
capabilities.textDocument.completion.completionItem.snippetSupport = true

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = 'rounded',
})
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = 'rounded',
})

local function format_buf(bufnr)
  vim.lsp.buf.format({
    bufnr = bufnr,
    filter = function(client)
      return client.name == 'null-ls' or client.name == 'metals'
    end,
  })
end

local function toggle_inlay_hints(bufnr, enable)
  vim.lsp.inlay_hint.enable(enable, {
    bufnr = bufnr,
  })
end

vim.api.nvim_create_user_command('ToggleInlayHints', function()
  vim.g.inlayhints = not vim.g.inlayhints
  toggle_inlay_hints(0, vim.g.inlayhints)
end, { desc = 'Toggle inlay hints globally' })

local function setup_keymaps()
  nmap('<leader>cr', vim.lsp.buf.rename, { desc = 'lsp: [r]ename' })
  nmap('<leader>ca', vim.lsp.buf.code_action, { desc = 'lsp: [c]ode [a]ction' })
  nmap('<leader>cf', function()
    format_buf(vim.api.nvim_get_current_buf())
  end, { desc = 'lsp: [c]ode [f]ormat' })

  nmap('<leader>ci', function()
    toggle_inlay_hints(0, not vim.lsp.inlay_hint.is_enabled())
  end, { desc = 'lsp: toggle inlay hints (buffer)' })
  nmap('<leader>cI', ':ToggleInlayHints<cr>', { desc = 'lsp: toggle inlay hints (global)' })

  nmap('gd', telescope_builtin.lsp_definitions, { desc = 'lsp: [g]oto [d]efinition' })
  nmap('gr', telescope_builtin.lsp_references, { desc = 'lsp: [g]oto [r]eferences' })
  nmap('gi', telescope_builtin.lsp_implementations, { desc = 'lsp: [g]oto [i]mplementation' })
  nmap('gD', vim.lsp.buf.declaration, { desc = 'lsp: [g]oto [D]eclaration' })
  nmap('gl', vim.lsp.codelens.run, { desc = 'lsp: [g]o through [l]ens' })
  nmap('gt', vim.lsp.buf.type_definition, { desc = 'lsp: [g]o to [t]ype definition' })

  nmap('<leader>sD', telescope_builtin.lsp_document_symbols, { desc = 'lsp: [d]ocument [s]ymbols' })
  nmap('<leader>sW', telescope_builtin.lsp_dynamic_workspace_symbols, { desc = 'lsp: [w]orkspace [s]ymbols' })

  -- See `:help K` for why this keymap
  map({ 'n', 'v' }, 'Q', vim.lsp.buf.hover, { desc = 'lsp: hover doc' })
  nmap('K', vim.lsp.buf.signature_help, { desc = 'lsp: signature doc' })
end

local function setup_auto_commands(client, bufnr)
  local server_capabilities = client.server_capabilities

  -- Format code before save :w
  vim.api.nvim_create_autocmd('BufWritePre', {
    callback = function()
      format_buf(bufnr)
    end,
    group = lsp_group,
  })

  --   -- Delete trailing whitespace on save at least, if formatter is not available
  --   vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
  --     pattern = '*',
  --     callback = function()
  --       local cursor = vim.fn.getpos('.')
  --       vim.cmd([[%s/\s\+$//e]])
  --       vim.fn.setpos('.', cursor)
  --     end,
  --   })

  vim.api.nvim_create_autocmd('CursorHold', {
    callback = function()
      if server_capabilities.documentHighlightProvider then
        pcall(vim.lsp.buf.document_highlight)
      end
    end,
    group = lsp_group,
  })

  vim.api.nvim_create_autocmd('CursorMoved', {
    callback = function()
      if server_capabilities.referencesProvider then
        pcall(vim.lsp.buf.clear_references)
      end
    end,
    group = lsp_group,
  })

  vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
    callback = function()
      if server_capabilities.codeLensProvider then
        pcall(vim.lsp.codelens.refresh)
      end
    end,
    group = lsp_group,
  })

  -- disable inlay hints by default
  toggle_inlay_hints(0, vim.g.inlayhints)

  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'dap-repl' },
    callback = function()
      require('dap.ext.autocompl').attach(bufnr)
    end,
    group = lsp_group,
  })
end

local function attach_lsp(client, bufnr)
  setup_keymaps()
  setup_auto_commands(client, bufnr)
end

local servers = {
  dockerls = {},
  terraformls = {},
  bashls = {},
  yamlls = {
    settings = {
      yaml = {
        keyOrdering = false, -- disable alphabetic ordering of keys
      },
    },
  },
  gopls = {
    settings = {
      gopls = {
        -- setup inlay hints
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
      },
    },
  },
  tsserver = {
    settings = {
      javascript = {
        inlayHints = {
          includeInlayEnumMemberValueHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayParameterNameHints = 'literals', -- 'none' | 'literals' | 'all';
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayVariableTypeHints = false,
          includeInlayVariableTypeHintsWhenTypeMatchesName = false,
        },
      },
      typescript = {
        inlayHints = {
          includeInlayEnumMemberValueHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayParameterNameHints = 'literals', -- 'none' | 'literals' | 'all';
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayVariableTypeHints = false,
          includeInlayVariableTypeHintsWhenTypeMatchesName = false,
        },
      },
    },
  },
  lua_ls = {
    settings = {
      Lua = {
        workspace = {
          checkThirdParty = false,
        },
        telemetry = {
          enable = false,
        },
        hint = {
          enable = true,
        },
      },
    },
  },
  nil_ls = {
    settings = {
      ['nil'] = {
        autostart = true,
        testSetting = 42,
      },
    },
  },
}

-- neodev must be setup before lspconfig
require('neodev').setup({
  library = {
    plugins = { 'nvim-dap-ui', 'neotest' },
  },
})

local mason_lspconfig = require('mason-lspconfig')
mason_lspconfig.setup({
  ensure_installed = vim.tbl_keys(servers),
  automatic_installation = false,
})

-- rust LSP is setup by rust plugin
local manually_installed = { 'rust_analyzer' }
mason_lspconfig.setup_handlers({
  function(server_name)
    if not has_value(manually_installed, server_name) then
      local server_config = servers[server_name]
      if server_config then
        require('lspconfig')[server_name].setup({
          capabilities = capabilities,
          on_attach = attach_lsp,
          settings = server_config.settings or {},
        })
      end
    end
  end,
})

-- Languages are at ${workspaceDir}/lua/language folder
require('language.js').setup(lsp_group)
require('language.lua').setup(lsp_group)
require('language.go').setup(lsp_group)
require('language.scala').setup(lsp_group, capabilities, attach_lsp)
require('language.rust').setup(lsp_group, capabilities, attach_lsp)
