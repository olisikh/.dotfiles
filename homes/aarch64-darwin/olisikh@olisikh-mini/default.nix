{ lib, namespace, ... }:
let
  inherit (lib.${namespace}) enabled;
in
{
  olisikh = {
    core.user = enabled;

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
          "com.apollographql.ijplugin"
          "com.anthropic.code.plugin"
          "com.github.copilot"
          "com.github.catppuccin.jetbrains"
          "com.github.catppuccin.jetbrains_icons"
          "nix-idea"
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
      gemini = enabled;
      copilot = enabled;
      opencode = enabled;

    };

    security = {
      crypto = enabled;
      sops = {
        enable = true;
        secrets = {
          elevenlabs = {
            key = "ai/elevenlabs";
            name = "ai/elevenlabs";
          };

          telegramBotToken = {
            key = "openclaw/telegramBotToken";
            name = "openclaw/telegramBotToken";
          };
          openclawGatewayToken = {
            key = "openclaw/gatewayToken";
            name = "openclaw/gatewayToken";
          };
          openclawOpencode = {
            key = "openclaw/opencode";
            name = "openclaw/opencode";
          };
          openclawGemini = {
            key = "openclaw/gemini";
            name = "openclaw/gemini";
          };
          openclawOllama = {
            key = "openclaw/ollama";
            name = "openclaw/ollama";
          };

          hermesGithub = {
            key = "hermes/github";
            name = "hermes/github";
          };
          hermesGemini = {
            key = "hermes/gemini";
            name = "hermes/gemini";
          };
          hermesOpencode = {
            key = "hermes/opencode";
            name = "hermes/opencode";
          };
          hermesOllama = {
            key = "hermes/ollama";
            name = "hermes/ollama";
          };

          tailscaleGolinkAuthKey = {
            key = "tailscale/golinkAuthKey";
            name = "tailscale/golink-auth-key";
          };
        };
      };
    };

    media.tools = enabled;
    utils = enabled;

    dev.shell = {
      zsh = enabled;
      antidote = enabled;
      direnv = enabled;
      fzf = enabled;
      ripgrep = enabled;
      starship = enabled;
      yazi = enabled;
      nixvim = {
        enable = true;
        plugins.obsidian.workspaces = [
          {
            name = "default";
            path = "~/notes";
          }
        ];
      };
      fd = enabled;
      eza = enabled;
      jq = enabled;
      yq = enabled;
      just = enabled;
      bat = enabled;
      pay-respects = enabled;
      zoxide = enabled;
    };
  };
}
