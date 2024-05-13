local uu = require('user.utils')
local nmap = uu.nmap
local map = uu.map

local telescope_builtin = require('telescope.builtin')
local lsp_group = vim.api.nvim_create_augroup('UserLsp', { clear = true })
local cmp_lsp = require('cmp_nvim_lsp')

-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
local capabilities = cmp_lsp.default_capabilities(vim.lsp.protocol.make_client_capabilities())
capabilities.textDocument.completion.completionItem.snippetSupport = true

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, { border = 'rounded' })
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = 'rounded' })

---Format buffer
---@param bufnr integer buffer num
---@param range range? {start:integer[], end:integer[]}
local function format_buf(bufnr, range)
  vim.lsp.buf.format({ bufnr = bufnr, range = range })
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

---Sets up keymaps for LSP buffer
---@param client vim.lsp.Client
---@param bufnr integer buffer num
local function setup_lsp_buffer(client, bufnr)
  local server_capabilities = client.server_capabilities or {}

  if server_capabilities.renameProvider then
    nmap('<leader>cr', vim.lsp.buf.rename, { desc = 'lsp: [r]ename' })
  end

  if server_capabilities.codeActionProvider then
    nmap('<leader>ca', vim.lsp.buf.code_action, { desc = 'lsp: [c]ode [a]ction' })
  end

  if server_capabilities.documentFormattingProvider then
    nmap('<leader>cf', function()
      format_buf(bufnr)
    end, { desc = 'lsp: [c]ode [f]ormat' })

    -- Format code before save :w
    vim.api.nvim_create_autocmd('BufWritePre', {
      callback = function()
        format_buf(bufnr)
      end,
      buffer = bufnr,
      group = lsp_group,
    })
  end

  if server_capabilities.documentRangeFormattingProvider then
    map('v', '<leader>cf', function()
      local vstart = vim.fn.getpos("'<")
      local vend = vim.fn.getpos("'>")

      format_buf(bufnr, { vstart, vend })
    end, { desc = 'lsp: [c]ode [f]ormat' })
  end

  if server_capabilities.inlayHintProvider then
    nmap('<leader>ci', function()
      toggle_inlay_hints(bufnr, not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }))
    end, { desc = 'lsp: toggle inlay hints (buffer)' })

    nmap('<leader>cI', ':ToggleInlayHints<cr>', { desc = 'lsp: toggle inlay hints (global)' })

    -- disable inlay hints by default
    toggle_inlay_hints(0, vim.g.inlayhints)
  end

  if server_capabilities.definitionProvider then
    nmap('gd', telescope_builtin.lsp_definitions, { desc = 'lsp: [g]oto [d]efinition' })
  end

  if server_capabilities.referencesProvider then
    nmap('gr', telescope_builtin.lsp_references, { desc = 'lsp: [g]oto [r]eferences' })

    vim.api.nvim_create_autocmd('CursorMoved', {
      callback = function()
        vim.lsp.buf.clear_references()
      end,
      buffer = bufnr,
      group = lsp_group,
    })
  end

  if server_capabilities.implementationProvider then
    nmap('gi', telescope_builtin.lsp_implementations, { desc = 'lsp: [g]oto [i]mplementation' })
  end

  if server_capabilities.declarationProvider then
    nmap('gD', vim.lsp.buf.declaration, { desc = 'lsp: [g]oto [D]eclaration' })
  end

  if server_capabilities.codeLensProvider then
    nmap('gl', vim.lsp.codelens.run, { desc = 'lsp: [g]o through [l]ens' })

    vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'InsertLeave' }, {
      callback = function()
        vim.lsp.codelens.refresh({ bufnr = bufnr })
      end,
      buffer = bufnr,
      group = lsp_group,
    })
  end

  if server_capabilities.typeDefinitionProvider then
    nmap('gt', vim.lsp.buf.type_definition, { desc = 'lsp: [g]o to [t]ype definition' })
  end

  if server_capabilities.documentSymbolProvider then
    nmap('<leader>sD', telescope_builtin.lsp_document_symbols, { desc = 'lsp: [d]ocument [s]ymbols' })
  end

  if server_capabilities.workspaceSymbolProvider then
    nmap('<leader>sW', telescope_builtin.lsp_dynamic_workspace_symbols, { desc = 'lsp: [w]orkspace [s]ymbols' })
  end

  -- See `:help K` for why this keymap
  if server_capabilities.hoverProvider then
    map({ 'n', 'v' }, 'Q', vim.lsp.buf.hover, { desc = 'lsp: hover doc' })
  end

  if server_capabilities.signatureHelpProvider then
    nmap('K', vim.lsp.buf.signature_help, { desc = 'lsp: signature doc' })
  end

  if server_capabilities.documentHighlightProvider then
    vim.api.nvim_create_autocmd('CursorHold', {
      callback = function()
        vim.lsp.buf.document_highlight()
      end,
      buffer = bufnr,
      group = lsp_group,
    })
  end

  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'dap-repl' },
    callback = function()
      require('dap.ext.autocompl').attach(bufnr)
    end,
    group = lsp_group,
  })
end

local servers = {
  dockerls = {},
  terraformls = {},
  rnix = {},
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

-- rust LSP is setup by rust plugin
local plugin_managed_servers = { 'rust_analyzer' }

local mason_lspconfig = require('mason-lspconfig')
mason_lspconfig.setup({
  ensure_installed = vim.tbl_keys(servers),
  automatic_installation = false,
})

mason_lspconfig.setup_handlers({
  function(server_name)
    if not vim.list_contains(plugin_managed_servers, server_name) then
      local settings = servers[server_name]

      if settings == nil then
        vim.print('[warn] add config for LSP server: ' .. server_name)
        settings = {}
      end

      require('lspconfig')[server_name].setup({
        capabilities = capabilities,
        settings = settings,
      })
    end
  end,
})

-- Setup all keymaps and autocommands for the buffer whenever LSP attaches
vim.api.nvim_create_autocmd('LspAttach', {
  group = lsp_group,
  callback = function(opts)
    local bufnr = opts.buf
    local client = vim.lsp.get_client_by_id(opts.data.client_id)

    if client then
      setup_lsp_buffer(client, bufnr)
    end
  end,
})

-- Languages are at ${workspaceDir}/lua/language folder
require('user.lsp.js').setup(lsp_group)
require('user.lsp.lua').setup(lsp_group)
require('user.lsp.go').setup(lsp_group)
require('user.lsp.scala').setup(lsp_group, capabilities)
require('user.lsp.rust').setup(lsp_group, capabilities)
