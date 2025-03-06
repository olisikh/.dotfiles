{ nixvimLib }: {
  luasnip = {
    enable = true;

    fromVscode = [
      { } # load snippets from friendly-snippets
      { paths = "./snippets"; } # load personal snippets from ~/.config/nvim/snippets
    ];
  };
}
