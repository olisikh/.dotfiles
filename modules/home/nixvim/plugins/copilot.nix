{ pkgs, ... }:
{
  plugins = {
    "copilot-lsp" = {
      enable = true;
    };

    "copilot-lua" = {
      enable = true;
      settings = {
        panel = {
          enabled = false;
        };
        suggestion = {
          enabled = true;
          auto_trigger = true;
          keymap = {
            accept = "<M-a>";
            accept_word = false;
            accept_line = false;
            next = "<M-]>";
            prev = "<M-[>";
            dismiss = "<C-]>";
          };
        };
        nes = {
          enabled = true; # requires copilot-lsp as a dependency
          auto_trigger = true;
          keymap = {
            accept_and_goto = false;
            accept = false;
            dismiss = false;
          };
        };
      };
    };
  };

  extraPlugins = [ pkgs.vimPlugins.copilot-lualine ];
}
