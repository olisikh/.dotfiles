-- nvim-cmp setup
local cmp = require('cmp')
local luasnip = require('luasnip')
local lspkind = require('lspkind')

luasnip.config.setup({})

cmp.setup({
  window = {
    completion = {
      border = 'single',
      scrollbar = '║',
    },
    documentation = {
      border = nil,
      scrollbar = '',
    },
  },
  confirmation = {
    completeopt = 'menu,menuone,noinsert',
  },
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-e>'] = cmp.mapping.close(),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<cr>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = {
    { name = 'codeium' },
    {
      name = 'nvim_lsp',
      -- entry_filter = function(entry, _)
      --   return cmp.lsp.CompletionItemKind.Text ~= entry:get_kind()
      -- end,
    },
    { name = 'luasnip' },
    { name = 'crates' },
    { name = 'nvim_lsp_signature_help' },
  },
  formatting = {
    format = lspkind.cmp_format({
      mode = 'symbol_text',  -- show only symbol annotations
      maxwidth = 50,         -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
      ellipsis_char = '...', -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
      symbol_map = { Codeium = '' },

      -- The function below will be called before any actual modifications from lspkind
      -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
      before = function(entry, vim_item)
        return vim_item
      end,
    }),
  },
})
