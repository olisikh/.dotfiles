{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf recursiveUpdate types optionalAttrs;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.openclaw;

  mkEnvSecretRef = envVar: "$" + "{${envVar}}";
  managedConfigPath = "${config.home.homeDirectory}/.openclaw/openclaw.json";

  gatewayTokenSecretPath = "${cfg.sopsSecretsDir}/${cfg.gatewayTokenSopsName}";
  telegramBotTokenSecretPath = "${cfg.sopsSecretsDir}/${cfg.telegramBotTokenSopsName}";
  memoryApiKeySecretPath = "${cfg.sopsSecretsDir}/${cfg.memorySearchApiKeySopsName}";

  defaultOpenClawConfig = {
    auth = {
      profiles = {
        "openai-codex:default" = {
          provider = "openai-codex";
          mode = "oauth";
        };
      };
    };

    agents = {
      defaults = {
        model = {
          primary = cfg.modelPrimary;
        };
        models = {
          "${cfg.modelPrimary}" = { };
        };
        workspace = "${config.home.homeDirectory}/.openclaw/workspace";
        compaction = {
          mode = "safeguard";
        };
        memorySearch = {
          enabled = true;
          provider = "gemini";
          model = "gemini-embedding-2-preview";
          remote = {
            apiKey = mkEnvSecretRef cfg.memorySearchApiKeyEnvVar;
          };
        };
      };
    };

    tools = {
      profile = "coding";
      web = {
        search = {
          provider = "brave";
        };
      };
      sessions = {
        visibility = "all";
      };
    };

    commands = {
      native = "auto";
      nativeSkills = "auto";
      restart = true;
      ownerDisplay = "raw";
    };

    session = {
      dmScope = "per-channel-peer";
    };

    hooks = {
      internal = {
        enabled = true;
        entries = {
          session-memory = {
            enabled = true;
          };
          command-logger = {
            enabled = true;
          };
          bootstrap-extra-files = {
            enabled = true;
          };
          boot-md = {
            enabled = true;
          };
        };
      };
    };

    channels = {
      telegram = {
        enabled = true;
        dmPolicy = "allowlist";
        botToken = mkEnvSecretRef cfg.telegramBotTokenEnvVar;
        allowFrom = cfg.telegramAllowFrom;
        groupPolicy = "allowlist";
        streaming = "partial";
      };
    };

    gateway = {
      port = 18789;
      mode = "local";
      bind = "auto";
      auth = {
        mode = "token";
        token = mkEnvSecretRef cfg.gatewayTokenEnvVar;
      };
      tailscale = {
        mode = "off";
        resetOnExit = false;
      };
      nodes = {
        denyCommands = [
          "camera.snap"
          "camera.clip"
          "screen.record"
          "contacts.add"
          "calendar.add"
          "reminders.add"
          "sms.send"
        ];
      };
    };

    plugins = {
      allow = [
        "acpx"
        "telegram"
        "openclaw-web-search"
      ];
      load = {
        paths = [
          cfg.acpxExtensionPath
        ];
      };
      entries = {
        telegram = {
          enabled = true;
        };
        acpx = {
          enabled = true;
        };
        openclaw-web-search = {
          enabled = true;
        };
      };
    };
  };
in
{
  options.${namespace}.openclaw = with types; {
    enable = mkBoolOpt false "Enable OpenClaw with a Nix-managed ~/.openclaw/openclaw.json";
    modelPrimary = mkOpt str "openai-codex/gpt-5.3-codex" "Primary OpenClaw model reference";
    telegramAllowFrom = mkOpt (listOf str) [ "3942079" ] "Telegram allowlist user IDs";
    acpxExtensionPath = mkOpt str "/opt/homebrew/lib/node_modules/openclaw/extensions/acpx" "Path to ACPX plugin";

    # NOTE: Secrets are intentionally externalized using OpenClaw env SecretRefs like ${OPENCLAW_GATEWAY_TOKEN}.
    # NOTE: This module can bootstrap those env vars from sops-nix decrypted files at runtime.
    memorySearchApiKeyEnvVar = mkOpt str "GEMINI_API_KEY" "Env var name used for agents.defaults.memorySearch.remote.apiKey";
    telegramBotTokenEnvVar = mkOpt str "OPENCLAW_TELEGRAM_BOT_TOKEN" "Env var name used for channels.telegram.botToken";
    gatewayTokenEnvVar = mkOpt str "OPENCLAW_GATEWAY_TOKEN" "Env var name used for gateway.auth.token";

    useSopsSecrets = mkBoolOpt true "Load OpenClaw secret env vars from sops-nix decrypted files";
    sopsSecretsDir = mkOpt str "${config.home.homeDirectory}/.config/sops-nix/secrets" "Directory where sops-nix writes decrypted secrets";
    memorySearchApiKeySopsName = mkOpt str "gemini" "sops secret filename containing the memory embedding API key";
    telegramBotTokenSopsName = mkOpt str "openclawTelegramBotToken" "sops secret filename containing Telegram bot token";
    gatewayTokenSopsName = mkOpt str "openclawGatewayToken" "sops secret filename containing OpenClaw gateway token";

    extraConfig = mkOpt attrs { } "Additional OpenClaw config recursively merged over the module defaults";
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ pkgs.openclaw ];

      file = {
        ".openclaw/openclaw.json".text = builtins.toJSON (
          recursiveUpdate defaultOpenClawConfig cfg.extraConfig
        );
      } // optionalAttrs cfg.useSopsSecrets {
        ".local/bin/openclaw-with-secrets" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            set -euo pipefail

            read_secret() {
              local file="$1"
              if [[ ! -r "$file" ]]; then
                echo "openclaw-with-secrets: missing readable secret file: $file" >&2
                exit 1
              fi
              tr -d '\r\n' < "$file"
            }

            export ${cfg.gatewayTokenEnvVar}="$(read_secret '${gatewayTokenSecretPath}')"
            export ${cfg.telegramBotTokenEnvVar}="$(read_secret '${telegramBotTokenSecretPath}')"
            export ${cfg.memorySearchApiKeyEnvVar}="$(read_secret '${memoryApiKeySecretPath}')"

            exec ${pkgs.openclaw}/bin/openclaw "$@"
          '';
        };
      };

      sessionVariables = {
        OPENCLAW_CONFIG_PATH = managedConfigPath;
        OPENCLAW_NIX_MODE = "1";
      };
    };
  };
}
