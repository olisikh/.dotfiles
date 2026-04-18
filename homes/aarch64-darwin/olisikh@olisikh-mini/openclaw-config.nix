{ homeDirectory }:
{
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
      "gemini:default" = {
        provider = "gemini";
        mode = "api_key";
      };
    };
  };

  agents = {
    defaults = {
      model = {
        primary = "openai-codex/gpt-5.4";
        fallbacks = [ "opencode-go/kimi-k2.5" ];
      };
      models = {
        "openai-codex/gpt-5.3-codex" = {
          alias = "Codex";
        };
        "opencode-go/kimi-k2.5" = {
          alias = "Kimi";
        };
        "opencode-go/glm-5" = {
          alias = "GLM";
        };
        "opencode-go/minimax-m2.5" = {
          alias = "MiniMax";
        };
      };
      workspace = "${homeDirectory}/.openclaw/workspace";
      memorySearch = {
        enabled = true;
        provider = "gemini";
        remote = { };
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
    list = [
      {
        id = "main";
        default = true;
        workspace = "${homeDirectory}/.openclaw/workspace";
      }
      {
        id = "wife";
        default = false;
        workspace = "${homeDirectory}/.openclaw/workspace-wife";
        sandbox = {
          mode = "off";
        };
        tools = {
          deny = [
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
            "browser"
            "subagents"
          ];
        };
      }
    ];
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
    debug = true;
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
      capabilities = {
        inlineButtons = "dm";
      };
      execApprovals = {
        enabled = true;
        approvers = [ "3942079" ];
        target = "dm";
      };
      enabled = true;
      dmPolicy = "allowlist";
      allowFrom = [ "3942079" "13252999" ];
      groupAllowFrom = [ "3942079" "13252999" ];
      groupPolicy = "allowlist";
      groups = {
        "*" = {
          requireMention = true;
        };
      };
      streaming = {
        mode = "partial";
      };
    };
  };

  gateway = {
    port = 18789;
    mode = "local";
    bind = "auto";
    controlUi = {
      allowedOrigins = [
        "http://127.0.0.1:18789"
        "http://localhost:18789"
        "http://192.168.2.30:18789"
      ];
    };
    auth = {
      mode = "token";
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
      "browser"
      "active-memory"
      "telegram"
      "ollama"
      "google"
      "microsoft"
      "elevenlabs"
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
      browser = {
        enabled = true;
        config = { };
      };
      active-memory = {
        enabled = true;

        # NOTE: configuration reference: https://github.com/openclaw/openclaw/blob/main/docs/concepts/active-memory.md
        config = {
          enabled = true;
          agents = [ "main" ];
          allowedChatTypes = [ "direct" ];
          model = "google/gemini-2.5-flash";
          timeoutMs = 15000;
          logging = true;
        };
      };
      ollama = {
        enabled = true;
        config = { };
      };
      google = {
        enabled = true;
        config = {
          webSearch = { };
        };
      };
      microsoft = {
        enabled = true;
        config = { };
      };
      elevenlabs = {
        enabled = true;
        config = { };
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

  bindings = [
    {
      agentId = "wife";
      match = {
        channel = "telegram";
        peer = {
          kind = "direct";
          id = "13252999";
        };
      };
    }
  ];

  messages = {
    ackReactionScope = "group-mentions";
    tts = {
      auto = "inbound";
      provider = "microsoft";
    };
  };

  skills = {
    install = {
      nodeManager = "pnpm";
    };
  };
}
