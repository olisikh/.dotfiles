{ lib, namespace, config, pkgs, ... }:
let
  inherit (lib.${namespace}) enabled disabled;
in
{
  olisikh = {
    core = {
      user = {
        enable = true;
        packages = with pkgs; [ ];
      };
      sops = {
        enable = true;
        secrets = {
          userEmail = {
            path = "git/userEmail";
            key = "git/userEmail";
          };
          signingKey = {
            path = "git/signingKey";
            key = "git/signingKey";
          };
          opencode = {
            path = "ai/opencode";
            key = "ai/opencode";
          };
          gemini = {
            path = "ai/gemini";
            key = "ai/gemini";
          };
        };
      };
    };

    terminal = {
      direnv = enabled;
      zsh = enabled;
      fzf = enabled;
      zoxide = enabled;
      bat = enabled;
      ripgrep = enabled;
      starship = enabled;
      git = enabled;
      yazi = enabled;
      nixvim = {
        enable = true;
        # Disable Java support on work laptop
        plugins.nvim-java = disabled;
      };
    };

    apps = {
      wezterm = enabled;
      sketchybar = enabled;
    };

    editor = {
      vscode = enabled;
      intellij-idea = {
        enable = true;
        plugins = [
          "com.github.catppuccin.jetbrains"
          "com.github.catppuccin.jetbrains_icons"
          "org.intellij.scala"
          "org.jetbrains.kotlin"
          "org.intellij.plugins.hcl"
          "Docker"
          "IdeaVIM"
          "Lombook Plugin"
          "youngstead.relative-line-numbers"
        ];
      };
    };

    ai = {
      opencode = enabled;
    };
  };
}
