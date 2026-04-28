{ lib, namespace, ... }:
let
  inherit (lib.${namespace}) enabled disabled;
in
{
  olisikh = {
    core = {
      user = {
        enable = true;
        sessionVariables = {
          METALS_OPTS = "-Djavax.net.ssl.trustStore=/opt/jdk17/lib/security/cacerts";
          JAVA_OPTS = "-Djavax.net.ssl.trustStore=/opt/jdk17/lib/security/cacerts";
        };
      };
      sops = {
        enable = true;
        secrets = {
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
      kafka = enabled;
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
      http.bruno = enabled;
    };

    apps = {
      wezterm = enabled;
      sketchybar = enabled;
    };

    editor = {
      vscode = enabled;
      android-studio = {
        enable = true;
        # Homebrew's Android Studio version can drift from nixpkgs, so pin the
        # actual config directory version that the installed app uses.
        configVersion = "2025.3.4";
        plugins = [
          "com.github.catppuccin.jetbrains"
          "com.github.catppuccin.jetbrains_icons"
          "IdeaVIM"
          "youngstead.relative-line-numbers"
        ];
      };
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
      gh-copilot = enabled;
      opencode = {
        enable = true;
        config = {
          enabled_providers = [ "github-copilot" ];
          model = "github-copilot/gpt-5.4";
          small_model = "github-copilot/gpt-5.4-mini";
        };
      };
    };

    security.crypto = enabled;
    utils = enabled;
  };
}
