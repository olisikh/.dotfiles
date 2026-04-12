{ lib, namespace, pkgs, config, ... }:
let
  inherit (lib.${namespace}) enabled;
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
    opencode = enabled;
    openclaw = {
      enable = true;

      # NOTE: with sops module enabled, provide secret files:
      # ~/.config/sops-nix/secrets/openclaw/gatewayToken
      # ~/.config/sops-nix/secrets/openclaw/telegramBotToken
      # ~/.config/sops-nix/secrets/ai/gemini
      # ~/.config/sops-nix/secrets/ai/elevenlabs
      config = import ./openclaw-config.nix {
        inherit (config.home) homeDirectory;
      };

      # NOTE: nix-openclaw's generated schema currently only allows
      # messages.tts.providers.<name>.apiKey, while OpenClaw 2026.4.11 accepts
      # richer provider config. Keep schema drift isolated in this raw layer.
      extraConfig = {
        messages.tts.providers.microsoft = {
          voice = "en-US-JennyNeural";
          lang = "en-US";
        };
      };

      sops = {
        memorySearchApiKey = "ai/gemini";
        elevenlabsApiKey = "ai/elevenlabs";
        gatewayToken = "openclaw/gatewayToken";
        telegramBotToken = "openclaw/telegramBotToken";
      };
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
          name = "git/userEmail";
        };
        # signingKey = {
        #   key = "git/signingKey";
        # };
        opencode = {
          key = "ai/opencode";
          name = "ai/opencode";
        };
        gemini = {
          key = "ai/gemini";
          name = "ai/gemini";
        };
        elevenlabs = {
          key = "ai/elevenlabs";
          name = "ai/elevenlabs";
        };
        openclawGatewayToken = {
          key = "openclaw/gatewayToken";
          name = "openclaw/gatewayToken";
        };
        openclawTelegramBotToken = {
          key = "openclaw/telegramBotToken";
          name = "openclaw/telegramBotToken";
        };
      };
    };
  };
}
