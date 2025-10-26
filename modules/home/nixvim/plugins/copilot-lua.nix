{ config, namespace, ... }:
let
  cfg = config.${namespace}.nixvim.plugins.copilot;
in
{
  copilot-lsp = {
    enable = cfg.enable-nes;
  };

  copilot-lua = {
    enable = cfg.enable;
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
        enabled = cfg.enable-nes; # requires copilot-lsp as a dependency
        auto_trigger = true;
        keymap = {
          accept_and_goto = false;
          accept = false;
          dismiss = false;
        };
      };
    };
  };
}
