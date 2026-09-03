{
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  olisikh = {
    core = {
      user = {
        enable = true;
        sessionVariables = {
          METALS_OPTS = lib.concatStringsSep " " [
            "-Djavax.net.ssl.trustStore=/opt/jdk17/lib/security/cacerts"

            "--add-opens=java.base/java.nio=ALL-UNNAMED"
            "--add-opens=java.base/sun.nio.ch=ALL-UNNAMED"

            "--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED"
            "--add-exports=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED"
            "--add-exports=jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED"
            "--add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED"
            "--add-exports=jdk.compiler/com.sun.tools.javac.jvm=ALL-UNNAMED"
            "--add-exports=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED"
            "--add-exports=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED"
            "--add-exports=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED"
            "--add-exports=jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED"
            "--add-exports=jdk.compiler/com.sun.tools.javac.resources=ALL-UNNAMED"
            "--add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED"
            "--add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED"

            "--add-opens=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED"
            "--add-opens=jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED"
            "--add-opens=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED"
            "--add-opens=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED"
          ];
          JAVA_OPTS = "-Djavax.net.ssl.trustStore=/opt/jdk17/lib/security/cacerts";
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
            obsidian.vaults = [
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
      };
      graphql.rover = enabled;
    };

    cloud = {
      terraform = enabled;
    };

    apps = {
      wezterm = enabled;
      sketchybar = enabled;
      obsidian = enabled;
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
      copilot = enabled;
      herdr = enabled;
      pi = {
        enable = true;
        config = {
          defaultModel = "gpt-5.6-terra-900k";
          defaultProvider = "openai-codex";
          defaultThinkingLevel = "high";
          subagents = {
            modelScope.allow = [ "openai-codex/*" ];
            agentOverrides = {
              reviewer = {
                model = "openai-codex/gpt-5.6-terra";
                thinking = "medium";
              };
              oracle = {
                model = "openai-codex/gpt-5.6-terra-900k";
                thinking = "medium";
              };
            };
          };
        };

        mcps = {
          mcpServers = {
            sherlockio = {
              command = "npx";
              args = [
                "-y"
                "@ebay/obsidian-mcp-client"
                "--permissions"
                "obsidian"
                "--server-id"
                "sherlockio"
              ];
            };
            compass = {
              command = "npx";
              args = [
                "-y"
                "@ebay/obsidian-mcp-client"
                "--permissions"
                "obsidian"
                "--server-id"
                "compass-mcp"
              ];
            };
            vector = {
              command = "npx";
              args = [
                "-y"
                "@ebay/obsidian-mcp-client"
                "--permissions"
                "obsidian"
                "--server-id"
                "obsidian-compass-vector"
              ];
            };
            deepsights = {
              command = "npx";
              args = [
                "-y"
                "@ebay/obsidian-mcp-client"
                "--permissions"
                "obsidian"
                "--server-id"
                "deepsights-mcp"
              ];
            };
            figma = {
              command = "npx";
              args = [
                "-y"
                "@ebay/obsidian-mcp-client"
                "--permissions"
                "obsidian"
                "--server-id"
                "figma-mcp"
              ];
            };
            jira.url = "https://mcp.aigateway.vip.ebay.com/mcp/backends/jira";
            glean.url = "https://ebay-be.glean.com/mcp/default";
            airtable.url = "https://mcp.aigateway.vip.ebay.com/mcp/backends/airtable";
            github.url = "https://mcp.aigateway.vip.ebay.com/mcp/backends/github";
          };
        };
      };
      opencode = {
        enable = true;
        package = pkgs.llm-agents.opencode;
        settings = {
          enabled_providers = [
            "github-copilot"
            "openai"
          ];
        };
      };
    };

    security = {
      crypto = enabled;

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
    utils = enabled;
  };
}
