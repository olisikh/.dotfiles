{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.openclaw;

  mkEnvSecretRef = envVar: "$" + "{${envVar}}";
  managedConfigPath = "${config.home.homeDirectory}/.openclaw/openclaw.json";

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
    # NOTE: Set these environment variables outside git (shell profile, launchd env, sops integration, etc.).
    memorySearchApiKeyEnvVar = mkOpt str "GEMINI_API_KEY" "Env var name used for agents.defaults.memorySearch.remote.apiKey";
    telegramBotTokenEnvVar = mkOpt str "OPENCLAW_TELEGRAM_BOT_TOKEN" "Env var name used for channels.telegram.botToken";
    gatewayTokenEnvVar = mkOpt str "OPENCLAW_GATEWAY_TOKEN" "Env var name used for gateway.auth.token";

    extraConfig = mkOpt attrs { } "Additional OpenClaw config recursively merged over the module defaults";
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ pkgs.openclaw ];

      file.".openclaw/openclaw.json".text = builtins.toJSON (
        recursiveUpdate defaultOpenClawConfig cfg.extraConfig
      );

      sessionVariables = {
        OPENCLAW_CONFIG_PATH = managedConfigPath;
        OPENCLAW_NIX_MODE = "1";
      };
    };
  };
}
