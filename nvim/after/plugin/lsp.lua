local helpers = require('helpers')
local nmap = helpers.nmap
local map = helpers.map
local contains = helpers.contains

local telescope_builtin = require('telescope.builtin')
local lsp_group = vim.api.nvim_create_augroup('UserLsp', { clear = true })
local cmp_lsp = require('cmp_nvim_lsp')

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = cmp_lsp.default_capabilities(vim.lsp.protocol.make_client_capabilities())
capabilities.textDocument.completion.completionItem.snippetSupport = true

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, { border = 'rounded' })
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = 'rounded' })

local function format_buf(bufnr)
  vim.lsp.buf.format({
    bufnr = bufnr,
    filter = function(client)
      local sources = {
        ['null-ls'] = {},
        metals = {},
        terraformls = {},
      }

      return sources[client.name] ~= nil
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

local function setup_keymaps(client, bufnr)
  nmap('<leader>cr', vim.lsp.buf.rename, { desc = 'lsp: [r]ename' })
  nmap('<leader>ca', vim.lsp.buf.code_action, { desc = 'lsp: [c]ode [a]ction' })
  nmap('<leader>cf', function()
    format_buf(bufnr)
  end, { desc = 'lsp: [c]ode [f]ormat' })

  nmap('<leader>ci', function()
    toggle_inlay_hints(bufnr, not vim.lsp.inlay_hint.is_enabled(bufnr))
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
    buffer = bufnr,
    group = lsp_group,
  })

  vim.api.nvim_create_autocmd('CursorHold', {
    callback = function()
      if server_capabilities.documentHighlightProvider then
        vim.lsp.buf.document_highlight()
      end
    end,
    buffer = bufnr,
    group = lsp_group,
  })

  vim.api.nvim_create_autocmd('CursorMoved', {
    callback = function()
      if server_capabilities.referencesProvider then
        vim.lsp.buf.clear_references()
      end
    end,
    buffer = bufnr,
    group = lsp_group,
  })

  vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
    callback = function()
      if server_capabilities.codeLensProvider then
        vim.lsp.codelens.refresh({ bufnr = bufnr })
      end
    end,
    buffer = bufnr,
    group = lsp_group,
  })

  -- disable inlay hints by default
  if server_capabilities.inlayHintProvider then
    toggle_inlay_hints(0, vim.g.inlayhints)
  end

  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'dap-repl' },
    callback = function()
      require('dap.ext.autocompl').attach(bufnr)
    end,
    group = lsp_group,
  })
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = lsp_group,
  callback = function(opts)
    local bufnr = opts.buf
    local client = vim.lsp.get_client_by_id(opts.data.client_id)

    setup_keymaps(client, bufnr)
    setup_auto_commands(client, bufnr)
  end,
})

local servers = {
  dockerls = {},
  terraformls = {},
  bashls = {},
  yamlls = {
    yaml = {
      keyOrdering = false, -- disable alphabetic ordering of keys
    },
  },
  gopls = {
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
  tsserver = {
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
  lua_ls = {
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
  nil_ls = {
    ['nil'] = {
      autostart = true,
      testSetting = 42,
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
local plugin_managed_servers = { 'rust_analyzer' }

mason_lspconfig.setup_handlers({
  function(server_name)
    if not contains(plugin_managed_servers, server_name) then
      local settings = servers[server_name] or {}
      require('lspconfig')[server_name].setup({
        capabilities = capabilities,
        settings = settings,
      })
    end
  end,
})

-- Languages are at ${workspaceDir}/lua/language folder
require('language.js').setup(lsp_group)
require('language.lua').setup(lsp_group)
require('language.go').setup(lsp_group)
require('language.scala').setup(lsp_group, capabilities)
require('language.rust').setup(lsp_group, capabilities)
