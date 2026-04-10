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
      # ~/.config/sops-nix/secrets/openclaw/gatewayToken
      # ~/.config/sops-nix/secrets/openclaw/telegramBotToken
      # ~/.config/sops-nix/secrets/gemini
      config = openclawConfig;
      gatewayTokenSopsName = "openclaw/gatewayToken";
      telegramBotTokenSopsName = "openclaw/telegramBotToken";
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
          key = "git/userEmail";
        };
        signingKey = {
          key = "git/signingKey";
        };
        opencode = {
          key = "ai/opencode/apiKey";
        };
        openai = {
          key = "ai/openai/apiKey";
        };
        openrouter = {
          key = "ai/openrouter/apiKey";
        };
        gemini = {
          key = "ai/gemini/apiKey";
        };
        openclawGatewayToken = {
          key = "ai/openclaw/gatewayToken";
          name = "openclaw/gatewayToken";
        };
        openclawTelegramBotToken = {
          key = "ai/openclaw/telegramBotToken";
          name = "openclaw/telegramBotToken";
        };
      };
    };
  };
}
