{ ... }: {
  luasnip = {
    enable = true;

    # NOTE: snippets docs: https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md#snipmate
    fromVscode = [
      { } # load snippets from friendly-snippets
      { paths = "./snippets"; } # load personal snippets from ~/.config/nvim/snippets
    ];
  };
}
