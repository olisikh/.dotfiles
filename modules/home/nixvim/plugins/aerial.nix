{ pkgs, lib, ... }:
{
  plugins.aerial = {
    enable = true;
    package = pkgs.vimPlugins.aerial-nvim;

    settings = {
      on_attach = lib.nixvim.mkRaw
        # lua
        ''
          function(bufnr)
            vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
            vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
          end
        '';
    };
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>o";
      action = ":AerialToggle!<cr>";
      options = {
        desc = "aerial: toggle outline view";
      };
    }
  ];
}

