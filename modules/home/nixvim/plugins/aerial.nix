{ pkgs, lib, ... }:
{
  plugins.aerial = {
    enable = true;
    package = pkgs.vimPlugins.aerial-nvim;
    doCheck = false;

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
      key = "<leader>co";
      action = ":AerialToggle!<cr>";
      options = {
        desc = "aerial: toggle [c]ode [o]utline";
      };
    }
  ];
}

