{ lib, namespace, ... }:
let
  inherit (lib.${namespace}) enabled;
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
        antidote = enabled;
        direnv = enabled;
        fzf = enabled;
        ripgrep = enabled;
        starship = enabled;
        yazi = enabled;
        nixvim = {
          enable = true;
          plugins = {
            obsidian.workspaces = [
              {
                name = "default";
                path = "~/notes";
              }
            ];
            nvim-java = {
              enable = true;
              runtimes = [
                {
                  name = "jdk11";
                  path = "/opt/jdk11";
                }
                {
                  name = "jdk17";
                  path = "/opt/jdk17";
                  default = true;
                }
                {
                  name = "jdk21";
                  path = "/opt/jdk21";
                }
                {
                  name = "jdk25";
                  path = "/opt/jdk25";
                }
              ];
              tools = {
                jdk = {
                  path = "/opt/jdk25";
                  version = "25";
                };
              };
            };
          };
        };
        fd = enabled;
        eza = enabled;
        jq = enabled;
        yq = enabled;
        just = enabled;
        bat = enabled;
        pay-respects = enabled;
        zoxide = enabled;
        scrcpy = enabled;
      };
      http = {
        bruno = enabled;
        postman = enabled;
      };
      graphql.rover = enabled;
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
          "com.apollographql.ijplugin"
          "com.anthropic.code.plugin"
          "com.github.copilot"
          "com.github.catppuccin.jetbrains"
          "com.github.catppuccin.jetbrains_icons"
          "nix-idea"
          "IdeaVIM"
          "youngstead.relative-line-numbers"
        ];
      };
      intellij-idea = {
        enable = true;
        plugins = [
          "com.apollographql.ijplugin"
          "com.anthropic.code.plugin"
          "com.intellij.reactivestreams"
          "com.jetbrains.jax.ws"
          "com.github.copilot"
          "com.github.catppuccin.jetbrains"
          "com.github.catppuccin.jetbrains_icons"
          "com.intellij.lang.jsgraphql"
          "com.netflix.graphql.dgs.intellijplugin"
          "com.intellij.spring.websocket"
          "com.intellij.spring.graphql"
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
