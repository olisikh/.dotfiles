local telescope_builtin = require('telescope.builtin')
local cmp_lsp = require('cmp_nvim_lsp')

local nmap = require('user.utils').nmap
local map = require('user.utils').map

local capabilities = cmp_lsp.default_capabilities(vim.lsp.protocol.make_client_capabilities())
capabilities.textDocument.completion.completionItem.snippetSupport = true

local lsp_group = vim.api.nvim_create_augroup('UserLsp', { clear = true })

local M = {}

M.lsp_group = lsp_group
M.capabilities = capabilities

---Sets up keymaps for LSP buffer
---@param client vim.lsp.Client
---@param bufnr integer buffer num
function M.on_attach(client, bufnr, init_opts)
  local server_capabilities = client.server_capabilities or {}

  if init_opts then
    if init_opts.format_null_ls then
      -- force formatting via none-ls if LSP formatting is not supported,
      -- but LSP client might still say otherwise
      server_capabilities.documentFormattingProvider = false
      server_capabilities.documentRangeFormattingProvider = false
    end
  end

  if server_capabilities.renameProvider then
    nmap('<leader>cr', vim.lsp.buf.rename, { desc = 'lsp: [r]ename' })
  end

  if server_capabilities.codeActionProvider then
    nmap('<leader>ca', vim.lsp.buf.code_action, { desc = 'lsp: [c]ode [a]ction' })
  end

  nmap('<leader>cd', vim.diagnostic.open_float, { desc = 'diagnostic: show [c]ode [d]iagnostic' })

  if server_capabilities.documentFormattingProvider then
    nmap('F', function()
      vim.lsp.buf.format()
    end, { desc = 'lsp: [c]ode [f]ormat' })
  end

  if server_capabilities.documentRangeFormattingProvider then
    map('v', 'F', function()
      local vstart = vim.fn.getpos("'<")
      local vend = vim.fn.getpos("'>")

      vim.lsp.buf.format({ range = { vstart, vend } })
    end, { desc = 'lsp: [c]ode [f]ormat' })
  end

  if server_capabilities.inlayHintProvider then
    nmap('<leader>ci', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end, { desc = 'lsp: toggle inlay hints (buffer)' })

    nmap('<leader>cI', ':ToggleInlayHints<cr>', { desc = 'lsp: toggle inlay hints (global)' })

    -- disable inlay hints by default
    vim.lsp.inlay_hint.enable(vim.g.inlay_hints)
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
        vim.lsp.codelens.refresh()
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

  if server_capabilities.signatureHelpProvider then
    map({ 'n', 'v' }, 'Q', vim.lsp.buf.signature_help, { desc = 'lsp: signature help' })
  end

  if server_capabilities.hoverProvider then
    nmap('K', vim.lsp.buf.hover, { desc = 'lsp: hover' })
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

return M
