{ lib, namespace, config, inputs, system, ... }:
let
  inherit (lib.${namespace}) enabled;
in
{
  olisikh = {
    core = {
      user = enabled;
      sops = {
        enable = true;
        secrets = {
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
          telegramBotToken = {
            key = "openclaw/telegramBotToken";
            name = "openclaw/telegramBotToken";
          };
          gatewayToken = {
            key = "openclaw/gatewayToken";
            name = "openclaw/gatewayToken";
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

    apps = {
      bitwarden = enabled;
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
      gemini = enabled;
      gh-copilot = enabled;
      opencode = enabled;

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
