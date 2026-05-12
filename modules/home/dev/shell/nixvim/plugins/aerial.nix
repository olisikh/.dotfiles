{ pkgs, lib, namespaceLib, ... }:
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
            local opts = { buffer = bufnr, silent = true, remap = false }
            vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", opts)
            vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", opts)
          end
        '';
    };
  };

  keymaps = namespaceLib.nixvimKeymaps [
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
