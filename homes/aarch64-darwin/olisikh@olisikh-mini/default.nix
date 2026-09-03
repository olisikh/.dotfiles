{ config, lib, namespace, pkgs, inputs, ... }:
let
  inherit (lib.${namespace}) enabled;
  hermesPackage = inputs.hermes-agent.packages.${pkgs.system}.messaging;
in
{
  programs.hermes-agent = {
    enable = true;
    package = hermesPackage;
  };

  services.hermes-agent = {
    enable = true;
    package = hermesPackage;
    hermesHome = "${config.home.homeDirectory}/.hermes";
    gateway.enable = false;

    # Public, reproducible Hermes policy. Unlisted keys remain in the private
    # ~/.hermes/config.yaml and are preserved by the Home Manager module.
    settings = {
      model = {
        default = "gpt-5.6-luna-900k";
        provider = "openai-codex";
      };

      fallback_providers = [
        {
          provider = "ollama-cloud";
          model = "glm-5.2:cloud";
        }
        {
          provider = "opencode-zen";
          model = "mimo-v2.5-free";
          base_url = "https://opencode.ai/zen/v1";
          api_mode = "chat_completions";
        }
        {
          provider = "opencode-zen";
          model = "deepseek-v4-flash-free";
          base_url = "https://opencode.ai/zen/v1";
          api_mode = "chat_completions";
        }
        {
          provider = "opencode-zen";
          model = "qwen3.6-plus-free";
          base_url = "https://opencode.ai/zen/v1";
          api_mode = "chat_completions";
        }
      ];

      toolsets = [ "hermes-cli" ];

      agent = {
        max_turns = 90;
        gateway_timeout = 1800;
        restart_drain_timeout = 60;
        api_max_retries = 3;
        tool_use_enforcement = "auto";
        task_completion_guidance = true;
        parallel_tool_call_guidance = true;
        environment_probe = true;
        coding_context = "auto";
        verify_on_stop = false;
        gateway_timeout_warning = 900;
        clarify_timeout = 600;
        gateway_notify_interval = 180;
        gateway_auto_continue_freshness = 3600;
        image_input_mode = "auto";
        disabled_toolsets = [ ];
        reasoning_overrides = {
          "gpt-5.6-luna" = "max";
          "deepseek-v4-flash:0731" = "max";
        };
        reasoning_effort = "max";
      };

      terminal = {
        backend = "local";
        timeout = 180;
        env_passthrough = [ ];
        home_mode = "auto";
        persistent_shell = true;
      };

      checkpoints = {
        enabled = true;
        max_snapshots = 50;
        max_total_size_mb = 500;
        max_file_size_mb = 10;
        auto_prune = false;
        retention_days = 7;
        min_interval_hours = 24;
        delete_orphans = true;
      };

      file_read_max_chars = 100000;
      mcp_discovery_timeout = 30;

      tool_output = {
        max_bytes = 50000;
        max_lines = 2000;
        max_line_length = 2000;
      };

      compression = {
        enabled = true;
        threshold = 0.80;
        provider = "ollama-cloud";
        model = "nemotron-3-nano:30b";
        timeout = 120;
      };

      prompt_caching = {
        enabled = true;
        ttl = 300;
        min_coding_score = 0.65;
        response_cache = true;
        response_cache_ttl = 300;
      };

      context.engine = "compressor";

      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
        write_approval = false;
        memory_char_limit = 2200;
        user_char_limit = 1375;
        provider = "holographic";
      };

      delegation = {
        model = "gpt-5.6-luna";
        provider = "openai-codex";
        inherit_mcp_toolsets = true;
        max_iterations = 15;
        child_timeout_seconds = 600;
        reasoning_effort = "max";
        max_concurrent_children = 2;
        max_spawn_depth = 1;
        orchestrator_enabled = true;
        subagent_auto_approve = false;
      };

      approvals = {
        mode = "smart";
        timeout = 60;
        cron_mode = "deny";
        mcp_reload_confirm = false;
        destructive_slash_confirm = false;
      };

      privacy.redact_pii = true;

      plugins.enabled = [
        "disk-cleanup"
        "herdr-agent-state"
        "image_gen/openai"
        "image_gen/openai-codex"
        "model-providers/ollama-cloud"
        "model-providers/openai-codex"
        "model-providers/opencode-zen"
        "platforms/telegram"
        "rtk-rewrite"
        "web/exa"
        "web/tavily"
      ];
    };
  };

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

      http = {
        bruno = enabled;
      };
    };

    cloud = {
      aws = enabled;
      terraform = enabled;
    };

    browser.brave = enabled;

    apps = {
      wezterm = enabled;
      sketchybar = enabled;
      obsidian = enabled;
    };

    editor = {
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
      herdr = enabled;
      opencode = enabled;
      pi = enabled;

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

          vikunjaDatabasePassword = {
            key = "vikunja/database-password";
            name = "vikunja/database-password";
          };
          vikunjaServiceSecret = {
            key = "vikunja/service-secret";
            name = "vikunja/service-secret";
          };
          vikunjaMcpApiToken = {
            key = "vikunja/mcp-api-token";
            name = "vikunja/mcp-api-token";
          };
          vikunjaHermesOwnerPassword = {
            key = "vikunja/hermes-owner-password";
            name = "vikunja/hermes-owner-password";
          };
          vikunjaHermesBotApiToken = {
            key = "vikunja/hermes-bot-api-token";
            name = "vikunja/hermes-bot-api-token";
          };
          vikunjaHermesWebhookSecret = {
            key = "vikunja/hermes-webhook-secret";
            name = "vikunja/hermes-webhook-secret";
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
        plugins = {
          obsidian.vaults = [
            {
              name = "default";
              path = "~/notes";
            }
          ];
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
    };
  };
}
