{ lib, namespace, pkgs, config, ... }:
let
  inherit (lib.${namespace}) enabled;

  openclawConfig = import ./openclaw-config.nix {
    inherit (config.home) homeDirectory;
  };
in
{
  olisikh = {
    direnv = enabled;
    zsh = enabled;
    fzf = enabled;
    zoxide = enabled;
    bat = enabled;
    wezterm = enabled;
    ripgrep = enabled;
    starship = enabled;
    git = enabled;
    yazi = enabled;
    nixvim = enabled;
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
    opencode = enabled;
    openclaw = {
      enable = true;

      # NOTE: with sops module enabled, provide secret files:
      # ~/.config/sops-nix/secrets/openclawGatewayToken
      # ~/.config/sops-nix/secrets/openclawTelegramBotToken
      # ~/.config/sops-nix/secrets/gemini
      config = openclawConfig;
    };
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
          path = "git/userEmail";
        };
        signingKey = {
          path = "git/signingKey";
        };
        opencode = {
          path = "ai/opencode/apiKey";
        };
        openai = {
          path = "ai/openai/apiKey";
        };
        openrouter = {
          path = "ai/openrouter/apiKey";
        };
        gemini = {
          path = "ai/gemini/apiKey";
        };
        openclawGatewayToken = {
          path = "ai/openclaw/gatewayToken";
        };
        openclawTelegramBotToken = {
          path = "ai/openclaw/telegramBotToken";
        };
      };
    };
  };
}
