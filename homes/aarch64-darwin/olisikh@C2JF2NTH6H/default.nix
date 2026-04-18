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

    fonts = enabled;

    dev = {
      node = enabled;
      jvm = enabled;
      python = enabled;
      git = enabled;
      shell = {
        zsh = enabled;
        direnv = enabled;
        fzf = enabled;
        ripgrep = enabled;
        starship = enabled;
        yazi = enabled;
        nixvim = {
          enable = true;
          # Disable Java support on work laptop
          plugins.nvim-java = disabled;
        };
        fd = enabled;
        eza = enabled;
        jq = enabled;
        yq = enabled;
        bat = enabled;
        pay-respects = enabled;
        zoxide = enabled;
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
      github-copilot-cli = enabled;
      opencode = enabled;
    };

    security.crypto = enabled;
    utils = enabled;
  };
}
