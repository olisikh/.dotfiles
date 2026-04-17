{ ... }: {
  plugins.neogen = {
    enable = true;
    settings = {
      snippet_engine = "luasnip";
    };
  };

  extraConfigLua = # lua
    ''
      vim.keymap.set("n", "<leader>ca", function() require("neogen").generate() end, { desc = "neogen: generate [a]nnotation" })
    '';
}

