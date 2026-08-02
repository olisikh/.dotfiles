{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.ai.pi;

  # Mirror opencode's provider/model setup: it talks to Ollama Cloud
  # (https://ollama.com/v1, BYOK) using kimi-k2.7-code as the main model and
  # deepseek-v4-flash as the small model. The apiKey is read at request time
  # from a file (pi runs `!cat ...` and caches the result), or a key can be
  # saved with `pi /login`.
  models = {
    providers = {
      ollama-cloud = {
        baseUrl = "https://ollama.com/v1";
        api = "openai-completions";
        apiKey = "!cat ${cfg.keyFile}";
        models = [
          {
            id = "kimi-k2.7-code";
            reasoning = true;
            contextWindow = 262144;
            maxTokens = 262144;
          }
          {
            id = "deepseek-v4-flash:0731";
            reasoning = true;
            contextWindow = 1000000;
            maxTokens = 384000;
          }
        ];
      };
    };
  };

  basicConfig = {
    defaultProvider = "ollama-cloud";
    defaultModel = "kimi-k2.7-code";

    theme = "dark";

    # Equivalent of opencode's compaction { auto = true; prune = false; reserved = 8000; }
    compaction = {
      enabled = true;
      reserveTokens = 10000;
    };

    retry = {
      enabled = true;
      maxRetries = 3;
    };

    # Equivalent of opencode's autoupdate = false (see also the
    # PI_SKIP_VERSION_CHECK env set by the llm-agents package).
    enableInstallTelemetry = false;
    enableAnalytics = false;

    # pi has no built-in permission system or MCP (both are opt-in extensions),
    # matching opencode's trust-heavy defaults: keep project trust on "ask".
    defaultProjectTrust = "ask";
  };

  finalConfig = recursiveUpdate basicConfig cfg.config;
in
{
  options.${namespace}.ai.pi = {
    enable = mkBoolOpt false "Enable pi terminal coding agent";
    keyFile = mkOpt types.str "${config.home.homeDirectory}/.config/sops-nix/secrets/ai/ollama" "Path to a file holding the ollama-cloud API key, read via `!cat` at request time. Defaults to the sops-nix materialized ai/ollama secret.";
    config = mkOpt types.attrs { } "Pi settings attrset merged into the module's base config";
  };

  config = mkIf cfg.enable {
    # The pi binary comes from the numtide/llm-agents.nix flake (exposed as
    # pkgs.llm-agents.pi via its shared-nixpkgs overlay) instead of the
    # lukasl-dev/pi.nix home-manager module.
    home.packages = [ pkgs.llm-agents.pi ];

    home.file = {
      # pi reads its agent config from ~/.pi/agent (the default
      # PI_CODING_AGENT_DIR). Write the files directly; pi writes back
      # runtime edits into settings.json.
      ".pi/agent/models.json".text = builtins.toJSON models;
      ".pi/agent/settings.json".text = builtins.toJSON finalConfig;
    };
  };
}
