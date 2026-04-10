{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf optionalAttrs recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.openclaw;

  gatewayTokenProvider = "gatewayToken";
  geminiApiKeyProvider = "geminiApiKey";

  gatewayTokenSecretPath = "${cfg.sopsSecretsDir}/${cfg.gatewayTokenSopsName}";
  telegramBotTokenSecretPath = "${cfg.sopsSecretsDir}/${cfg.telegramBotTokenSopsName}";
  memoryApiKeySecretPath = "${cfg.sopsSecretsDir}/${cfg.memorySearchApiKeySopsName}";

  mkModelEntries = models: modelEntries:
    (builtins.listToAttrs (
      map
        (model: {
          name = model;
          value = { };
        })
        models
    ))
    // modelEntries;

  mkFileSecretRef = provider: id: {
    source = "file";
    inherit provider id;
  };

  mkEnvSecretRef = envVar: {
    source = "env";
    provider = "env";
    id = envVar;
  };

  gatewayTokenSecretRef =
    if cfg.useSopsSecrets then
      mkFileSecretRef gatewayTokenProvider "value"
    else
      mkEnvSecretRef cfg.gatewayTokenEnvVar;

  memoryApiKeySecretRef =
    if cfg.useSopsSecrets then
      mkFileSecretRef geminiApiKeyProvider "value"
    else
      mkEnvSecretRef cfg.memorySearchApiKeyEnvVar;

  modelRef =
    if cfg.modelFallbacks == [ ] then
      cfg.modelPrimary
    else
      {
        primary = cfg.modelPrimary;
        fallbacks = cfg.modelFallbacks;
      };

  defaultOpenClawConfig = recursiveUpdate
    {
      meta = {
        # NOTE: Runtime-specific timestamps are intentionally not pinned in Nix.
        lastTouchedVersion = "2026.4.10";
      };

      auth = {
        profiles = {
          "openai-codex:default" = {
            provider = "openai-codex";
            mode = "oauth";
          };
          "opencode:default" = {
            provider = "opencode";
            mode = "api_key";
          };
          "opencode-go:default" = {
            provider = "opencode-go";
            mode = "api_key";
          };
        };
      };

      agents = {
        defaults = {
          model = modelRef;
          models = mkModelEntries cfg.models cfg.modelEntries;
          workspace = cfg.mainWorkspace;
          memorySearch = {
            enabled = true;
            provider = "gemini";
            remote = {
              apiKey = memoryApiKeySecretRef;
            };
            model = "gemini-embedding-2-preview";
          };
          compaction = {
            mode = "safeguard";
          };
          thinkingDefault = "high";
          maxConcurrent = 4;
          subagents = {
            maxConcurrent = 8;
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
            enabled = true;
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
        telegram =
          {
            capabilities = {
              inlineButtons = "dm";
            };
            execApprovals = {
              enabled = true;
              approvers = cfg.telegramExecApprovers;
              target = "dm";
            };
            enabled = true;
            dmPolicy = "allowlist";
            allowFrom = cfg.telegramAllowFrom;
            groupPolicy = "allowlist";
            groupAllowFrom = cfg.telegramGroupAllowFrom;
            groups = {
              "*" = {
                requireMention = true;
              };
            };
            streaming = {
              mode = "partial";
            };
          }
          // optionalAttrs cfg.useSopsSecrets {
            tokenFile = telegramBotTokenSecretPath;
          }
          // optionalAttrs (!cfg.useSopsSecrets) {
            botToken = mkEnvSecretRef cfg.telegramBotTokenEnvVar;
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
          token = gatewayTokenSecretRef;
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
          "google"
          "opencode-go"
          "opencode"
          "openai"
        ];
        entries = {
          telegram = {
            enabled = true;
            config = { };
          };
          acpx = {
            enabled = true;
            config = { };
          };
          ollama = {
            enabled = true;
            config = { };
          };
          google = {
            enabled = true;
            config = {
              webSearch = {
                apiKey = memoryApiKeySecretRef;
              };
            };
          };
          opencode-go = {
            enabled = true;
            config = { };
          };
          opencode = {
            enabled = true;
            config = { };
          };
          openai = {
            enabled = true;
            config = { };
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

      messages = {
        ackReactionScope = "group-mentions";
        tts = {
          auto = "inbound";
          provider = "elevenlabs";
          providers = {
            elevenlabs = {
              enabled = true;
              voiceId = cfg.messagesTtsElevenlabsVoiceId;
            };
            microsoft = {
              enabled = true;
              voice = cfg.messagesTtsMicrosoftVoice;
            };
          };
        };
      };

      skills = {
        install = {
          nodeManager = "pnpm";
        };
      };
    }
    (optionalAttrs cfg.useSopsSecrets {
      secrets = {
        providers = {
          "${gatewayTokenProvider}" = {
            source = "file";
            path = gatewayTokenSecretPath;
            mode = "singleValue";
          };
          "${geminiApiKeyProvider}" = {
            source = "file";
            path = memoryApiKeySecretPath;
            mode = "singleValue";
          };
        };
      };
    });
in
{
  options.${namespace}.openclaw = with types; {
    enable = mkBoolOpt false "Enable OpenClaw via nix-openclaw Home Manager module";

    modelPrimary = mkOpt str "openai-codex/gpt-5.4" "Primary OpenClaw model reference";
    modelFallbacks = mkOpt (listOf str) [ "opencode-go/kimi-k2.5" ] "Fallback model chain for agents.defaults.model";
    models = mkOpt (listOf str) [ "openai-codex/gpt-5.3-codex" ] "Additional OpenClaw model entries with empty config";
    modelEntries = mkOpt attrs
      {
        "opencode-go/kimi-k2.5" = {
          alias = "Kimi";
        };
        "opencode-go/glm-5" = {
          alias = "GLM";
        };
        "opencode-go/minimax-m2.5" = {
          alias = "MiniMax";
        };
      } "Additional/overriding OpenClaw model entries (supports aliases/settings)";

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
    telegramExecApprovers = mkOpt (listOf str) [ "3942079" ] "Telegram users allowed to approve exec requests";
    controlUiAllowedOrigins = mkOpt (listOf str) [
      "http://127.0.0.1:18789"
      "http://localhost:18789"
      "http://192.168.2.30:18789"
    ] "Gateway control UI allowed origins";

    useSopsSecrets = mkBoolOpt true "Read Telegram/Gateway/Memory-search secrets from sops-nix decrypted files";
    sopsSecretsDir = mkOpt str "${config.home.homeDirectory}/.config/sops-nix/secrets" "Directory where sops-nix writes decrypted secrets";
    memorySearchApiKeySopsName = mkOpt str "gemini" "sops secret filename containing Gemini API key";
    telegramBotTokenSopsName = mkOpt str "openclawTelegramBotToken" "sops secret filename containing Telegram bot token";
    gatewayTokenSopsName = mkOpt str "openclawGatewayToken" "sops secret filename containing OpenClaw gateway token";

    memorySearchApiKeyEnvVar = mkOpt str "GEMINI_API_KEY" "Fallback env var for memory search/Google web search API key when not using sops";
    telegramBotTokenEnvVar = mkOpt str "OPENCLAW_TELEGRAM_BOT_TOKEN" "Fallback env var for channels.telegram.botToken when not using sops";
    gatewayTokenEnvVar = mkOpt str "OPENCLAW_GATEWAY_TOKEN" "Fallback env var for gateway.auth.token when not using sops";

    messagesTtsElevenlabsVoiceId = mkOpt str "MFZUKuGQUsGJPQjTS4wC" "Voice ID for ElevenLabs TTS provider";
    messagesTtsMicrosoftVoice = mkOpt str "en-US-AvaMultilingualNeural" "Voice name for Microsoft TTS provider";

    documents = mkOpt (nullOr path) null "Optional directory with AGENTS.md/SOUL.md/TOOLS.md for OpenClaw workspace bootstrap";
    bundledPlugins = mkOpt attrs { } "Optional overrides for programs.openclaw.bundledPlugins";
    customPlugins = mkOpt (listOf attrs) [ ] "Extra programs.openclaw.customPlugins entries";

    extraConfig = mkOpt attrs { } "Additional OpenClaw config recursively merged over module defaults";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !(builtins.elem "web_search" cfg.wifeToolsDeny || builtins.elem "web_fetch" cfg.wifeToolsDeny);
        message = "olisikh.openclaw.wifeToolsDeny must not include web_search or web_fetch.";
      }
    ];

    programs.openclaw = {
      enable = true;
      workspaceDir = cfg.mainWorkspace;
      inherit (cfg) documents bundledPlugins customPlugins;
      config = recursiveUpdate defaultOpenClawConfig cfg.extraConfig;
    };
  };
}
