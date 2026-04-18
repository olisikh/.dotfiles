{ lib, namespace, pkgs, config, inputs, system, ... }:
let
  inherit (lib.${namespace}) enabled;

  qmdPkg = inputs.qmd.packages.${system}.qmd;
in
{
  olisikh = {
    core = {
      user = {
        enable = true;
        packages = with pkgs; [
          cmatrix
          (pulumi.withPackages (ps: with ps; [
            pulumi-nodejs
          ]))
          dotnet-sdk_10
          qmdPkg
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

    fonts = enabled;

    dev = {
      k8s = enabled;
      kafka = enabled;
      node = enabled;
      jvm = enabled;
      docker = enabled;
      python = enabled;
      git = enabled;
    };

    cloud = {
      aws = enabled;
      terraform = enabled;
    };

    browser.brave = enabled;
    apps.bitwarden = enabled;
    apps = {
      wezterm = enabled;
      sketchybar = enabled;
    };

    editor = {
      obsidian = enabled;
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
      whisper = enabled;
      antigravity = enabled;
      gemini-cli = enabled;
      github-copilot-cli = enabled;
      opencode = enabled;
      openclaw = {
        enable = true;

        config = import ./openclaw-config.nix {
          inherit (config.home) homeDirectory;

          qmdPath = (lib.getExe' qmdPkg "qmd");
        };

        # NOTE: nix-openclaw's generated schema currently only allows
        # messages.tts.providers.<name>.apiKey, while OpenClaw 2026.4.11 accepts
        # richer provider config. Keep schema drift isolated in this raw layer.
        extraConfig = {
          agents.defaults.imageGenerationModel.primary = "google/gemini-3.1-flash-image-preview";

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
    };

    security.crypto = enabled;
    media.tools = enabled;
    utils = enabled;

    dev.shell = {
      zsh = enabled;
      direnv = enabled;
      fzf = enabled;
      ripgrep = enabled;
      starship = enabled;
      yazi = enabled;
      nixvim = enabled;
      fd = enabled;
      eza = enabled;
      jq = enabled;
      yq = enabled;
      bat = enabled;
      pay-respects = enabled;
      zoxide = enabled;
    };
  };
}
