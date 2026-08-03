{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.ai.pi;

  basicConfig = {
    defaultProvider = "ollama-cloud";
    defaultModel = "deepseek-v4-flash:0731:max";
    defaultThinkingLevel = "high";

    theme = "catppuccin-mocha";

    # Pi installs declared npm packages into its agent directory on startup.
    # Pin the version so a future package release does not change the setup
    # unexpectedly.
    # @ifi/oh-pi is an installer rather than a Pi resource package. Declare
    # the packages it installs directly so this remains compatible with the
    # generated settings.json.
    packages = [
      "npm:pi-ollama-cloud"

      "npm:@ifi/pi-plan@0.5.1"
      "npm:@ifi/pi-spec@0.5.1"
      "npm:@ifi/pi-extension-subagents@0.5.1"
      "npm:@ifi/oh-pi-agents@0.5.1"
      {
        source = "npm:@ifi/oh-pi-skills@0.5.1";
        skills = [
          "!skills/improve-codebase-architecture/**"
          "!skills/grill-me/**"
        ];
      }
      "npm:@ifi/oh-pi-themes@0.5.1"
      "npm:@ifi/oh-pi-prompts@0.5.1"
      "npm:@ifi/oh-pi-ant-colony@0.5.1"
      "npm:@ifi/oh-pi-extensions@0.5.1"
    ];

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
      ".pi/agent/settings.json".text = builtins.toJSON finalConfig;
    };
  };
}
