{ lib, namespace, pkgs, ... }:
let
  inherit (lib.${namespace}) enabled disabled;
in
{
  olisikh = {
    core = {
      user = {
        enable = true;
        packages = with pkgs; [
          podman
          brave
          bitwarden-desktop
          openai-whisper
          antigravity
          gemini-cli
          obsidian
          vscode
          cmatrix
          (pulumi.withPackages (ps: with ps; [
            pulumi-nodejs
          ]))
          dotnet-sdk_10
        ];
      };
      sops = {
        enable = true;
        secrets = {
          userEmail = {
            key = "git/userEmail";
            name = "git/userEmail";
          };
          signingKey = {
            key = "git/signingKey";
            name = "git/signingKey";
          };
          opencode = {
            key = "ai/opencode";
            name = "ai/opencode";
          };
          openrouter = {
            key = "ai/openrouter";
            name = "ai/openrouter";
          };
          gemini = {
            key = "ai/gemini";
            name = "ai/gemini";
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
      nixvim = enabled;
    };

    apps = {
      wezterm = enabled;
      sketchybar = enabled;
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

    media = {
      iina = enabled;
      transmission = enabled;
    };

    ai = {
      opencode = enabled;
    };
  };
}
