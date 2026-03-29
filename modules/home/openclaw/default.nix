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

  mkModelEntries = models:
    builtins.listToAttrs (map (model: {
      name = model;
      value = { };
    }) models);

  defaultOpenClawConfig = {
    meta = {
      # NOTE: Runtime-specific timestamps are intentionally not pinned in Nix.
      lastTouchedVersion = "2026.3.23-2";
    };

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
        model = cfg.modelPrimary;
        models = mkModelEntries cfg.models;
        workspace = cfg.mainWorkspace;
        memorySearch = {
          enabled = true;
          provider = "gemini";
          remote = {
            apiKey = mkEnvSecretRef cfg.memorySearchApiKeyEnvVar;
          };
          model = "gemini-embedding-2-preview";
        };
        compaction = {
          mode = "safeguard";
        };
      };
      list =
        [
          {
            id = "main";
            default = true;
            workspace = cfg.mainWorkspace;
          }
        ]
        ++ lib.optional cfg.enableWifeAgent {
          id = "wife";
          default = false;
          workspace = cfg.wifeWorkspace;
          sandbox = {
            mode = "off";
          };
          tools = {
            deny = cfg.wifeToolsDeny;
          };
        };
    };

    tools = {
      profile = "coding";
      web = {
        search = {
          provider = "gemini";
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
        groupAllowFrom = cfg.telegramGroupAllowFrom;
        groups = {
          "*" = {
            requireMention = false;
          };
        };
      };
    };

    gateway = {
      port = 18789;
      mode = "local";
      bind = "auto";
      controlUi = {
        allowedOrigins = cfg.controlUiAllowedOrigins;
      };
      auth = {
        mode = "token";
        token = mkEnvSecretRef cfg.gatewayTokenEnvVar;
        rateLimit = {
          maxAttempts = 10;
          windowMs = 60000;
          lockoutMs = 300000;
        };
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
        "ollama"
        "openclaw-web-search"
        "google"
      ];
      load = {
        paths = [
          cfg.acpxExtensionPath
          cfg.ollamaExtensionPath
          cfg.googleExtensionPath
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
        ollama = {
          enabled = true;
        };
        google = {
          enabled = true;
          config = {
            webSearch = {
              apiKey = mkEnvSecretRef cfg.memorySearchApiKeyEnvVar;
            };
          };
        };
      };
    };

    bindings = lib.optional cfg.enableWifeAgent {
      agentId = "wife";
      match = {
        channel = "telegram";
        peer = {
          kind = "direct";
          id = cfg.wifeTelegramPeerId;
        };
      };
    };
  };
in
{
  options.${namespace}.openclaw = with types; {
    enable = mkBoolOpt false "Enable OpenClaw with a Nix-managed ~/.openclaw/openclaw.json";

    modelPrimary = mkOpt str "openai-codex/gpt-5.4" "Primary OpenClaw model reference";
    models = mkOpt (listOf str) [ "openai-codex/gpt-5.4" "openai-codex/gpt-5.3-codex" ] "OpenClaw model entries to register";

    mainWorkspace = mkOpt str "${config.home.homeDirectory}/.openclaw/workspace" "Main OpenClaw workspace path";
    enableWifeAgent = mkBoolOpt true "Enable secondary restricted OpenClaw agent bound to a direct Telegram peer";
    wifeWorkspace = mkOpt str "${config.home.homeDirectory}/.openclaw/workspace-wife" "Secondary agent workspace path";
    wifeTelegramPeerId = mkOpt str "13252999" "Telegram direct peer ID routed to wife agent";
    wifeToolsDeny = mkOpt (listOf str) [
      "exec"
      "process"
      "write"
      "edit"
      "apply_patch"
      "cron"
      "gateway"
      "nodes"
      "sessions_spawn"
      "sessions_send"
      "sessions_history"
      "sessions_list"
      "memory_get"
      "memory_search"
      "read"
      "browser"
      "image"
      "image_generate"
      "canvas"
      "subagents"
    ] "Strict deny list for wife agent tools. Keep web_search and web_fetch allowed.";

    telegramAllowFrom = mkOpt (listOf str) [ "3942079" "13252999" ] "Telegram DM allowlist user IDs";
    telegramGroupAllowFrom = mkOpt (listOf str) [ "3942079" "13252999" ] "Telegram group allowlist user IDs";
    controlUiAllowedOrigins = mkOpt (listOf str) [
      "http://127.0.0.1:18789"
      "http://localhost:18789"
      "http://192.168.2.30:18789"
    ] "Gateway control UI allowed origins";

    acpxExtensionPath = mkOpt str "/opt/homebrew/lib/node_modules/openclaw/dist/extensions/acpx" "Path to ACPX plugin";
    ollamaExtensionPath = mkOpt str "/opt/homebrew/lib/node_modules/openclaw/dist/extensions/ollama" "Path to Ollama plugin";
    googleExtensionPath = mkOpt str "/opt/homebrew/lib/node_modules/openclaw/dist/extensions/google" "Path to Google plugin";

    # NOTE: Secrets are intentionally externalized using OpenClaw env SecretRefs like ${OPENCLAW_GATEWAY_TOKEN}.
    # NOTE: This module bootstraps those env vars from sops-nix decrypted files at runtime.
    memorySearchApiKeyEnvVar = mkOpt str "GEMINI_API_KEY" "Env var name used for embedding and Google webSearch API keys";
    telegramBotTokenEnvVar = mkOpt str "OPENCLAW_TELEGRAM_BOT_TOKEN" "Env var name used for channels.telegram.botToken";
    gatewayTokenEnvVar = mkOpt str "OPENCLAW_GATEWAY_TOKEN" "Env var name used for gateway.auth.token";

    useSopsSecrets = mkBoolOpt true "Load OpenClaw secret env vars from sops-nix decrypted files";
    sopsSecretsDir = mkOpt str "${config.home.homeDirectory}/.config/sops-nix/secrets" "Directory where sops-nix writes decrypted secrets";
    memorySearchApiKeySopsName = mkOpt str "gemini" "sops secret filename containing Gemini API key";
    telegramBotTokenSopsName = mkOpt str "openclawTelegramBotToken" "sops secret filename containing Telegram bot token";
    gatewayTokenSopsName = mkOpt str "openclawGatewayToken" "sops secret filename containing OpenClaw gateway token";

    extraConfig = mkOpt attrs { } "Additional OpenClaw config recursively merged over module defaults";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !(builtins.elem "web_search" cfg.wifeToolsDeny || builtins.elem "web_fetch" cfg.wifeToolsDeny);
        message = "olisikh.openclaw.wifeToolsDeny must not include web_search or web_fetch.";
      }
    ];

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
