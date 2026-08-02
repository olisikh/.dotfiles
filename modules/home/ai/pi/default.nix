{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.ai.pi;

  homeDir = config.home.homeDirectory;

  # Reuse the opencode prompt files (they back opencode's plan/build/general/explore
  # agents) as pi prompt templates so the same intent is available via /plan,
  # /build, /general, and /explore. Plus a /commit template mirroring opencode's
  # command.commit.
  promptTemplates = [
    "${homeDir}/.config/opencode/prompts/plan.md"
    "${homeDir}/.config/opencode/prompts/build.md"
    "${homeDir}/.config/opencode/prompts/general.md"
    "${homeDir}/.config/opencode/prompts/explore.md"
    ./prompts/commit.md
  ];

  # Mirror opencode's provider/model setup: it talks to Ollama Cloud
  # (https://ollama.com/v1, BYOK) using kimi-k2.7-code as the main model and
  # deepseek-v4-flash as the small model. The apiKey is resolved at request time
  # from the OLLAMA_API_KEY env var, or a key can be saved with `pi /login`.
  modelsJson =
    builtins.toJSON {
      providers.ollama-cloud = {
        baseUrl = "https://ollama.com/v1";
        api = "openai-completions";
        apiKey = "$OLLAMA_API_KEY";
        models = [
          { id = "kimi-k2.7-code"; }
          { id = "deepseek-v4-flash"; }
        ];
      };
    };

  basicConfig = {
    defaultProvider = "ollama-cloud";
    defaultModel = "kimi-k2.7-code";

    theme = "dark";

    # Equivalent of opencode's compaction { auto = true; prune = false; reserved = 8000; }
    compaction = {
      enabled = true;
      reserveTokens = 8000;
    };

    retry = {
      enabled = true;
      maxRetries = 3;
    };

    # Equivalent of opencode's autoupdate = false (see also PI_SKIP_VERSION_CHECK env).
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
    config = mkOpt types.attrs { } "Pi settings attrset merged into the module's base config";
  };

  config = mkIf cfg.enable {
    programs.pi.coding-agent = {
      enable = true;
      settings = finalConfig;
      models = pkgs.writeText "pi-models.json" modelsJson;
      promptTemplates = promptTemplates;
      environment.PI_SKIP_VERSION_CHECK.value = "1";
    };
  };
}
