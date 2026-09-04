{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.ai.hermes;
  defaultPackage = inputs.llm-agents.packages.${pkgs.system}.hermes-agent;
  localeDir = "${inputs.hermes-agent}/locales";
  rtkRewritePlugin = pkgs.runCommand "rtk-rewrite-hermes-plugin" { } ''
    cp -R ${./plugins/rtk-rewrite}/. "$out"
  '';

  publicSettings = {
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

    gateway = {
      multiplex_profiles = true;
      multiplex_profile_allowlist = [ "wife" ];
    };

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
      threshold = 0.8;
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

  defaultConfig = {
    enable = mkBoolOpt false "Enable Hermes Agent";
    gateway.enable = mkBoolOpt false "Run the Hermes gateway as a Nix-managed service";
    package = mkOpt types.package defaultPackage "Hermes Agent package to install";
    extraPlugins = mkOpt (types.listOf types.package) [ ] ''
      Additional declarative Hermes directory plugins. Each package must expose
      plugin.yaml and __init__.py at its root.
    '';
    settings = mkOpt types.attrs publicSettings ''
      Public Hermes settings. Keys not declared here remain in the private
      ~/.hermes/config.yaml and are preserved by the official Home Manager module.
    '';
  };
in
{
  options.${namespace}.ai.hermes = defaultConfig;

  config = mkIf cfg.enable (lib.mkMerge [
    {
      home.sessionVariables.HERMES_BUNDLED_LOCALES = localeDir;

      programs.hermes-agent = {
        enable = true;
        package = cfg.package;
      };

      services.hermes-agent = {
        enable = true;
        package = cfg.package;
        hermesHome = "${config.home.homeDirectory}/.hermes";
        gateway.enable = cfg.gateway.enable;
        extraPackages = [
          pkgs.git
          pkgs.gh
          pkgs.rtk
          pkgs.ffmpeg
          pkgs.${namespace}.qmd
        ];
        extraPlugins = [ rtkRewritePlugin ] ++ cfg.extraPlugins;
        settings = cfg.settings;
      };
    }

    # The upstream module creates this agent only when the gateway is enabled.
    # Add the catalog path to that generated plist without writing it to the
    # private .env file or changing the agent's label/command line.
    (mkIf (pkgs.stdenv.isDarwin && cfg.gateway.enable) {
      launchd.agents.hermes-agent.config.EnvironmentVariables.HERMES_BUNDLED_LOCALES = localeDir;
    })
  ]);
}
