{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.ai.pi;

  basicConfig = {
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.6-luna";
    defaultThinkingLevel = "max";

    theme = "catppuccin-mocha";

    # Pi installs declared npm packages into its agent directory on startup.
    packages = [
      "npm:pi-ollama-cloud"
      "npm:pi-dynamic-workflows"

      "npm:@ifi/pi-plan"
      "npm:@ifi/pi-spec"
      "npm:@ifi/pi-extension-subagents"
      "npm:@ifi/oh-pi-agents"
      {
        source = "npm:@ifi/oh-pi-skills";
        skills = [
          "!skills/improve-codebase-architecture/**"
          "!skills/grill-me/**"
        ];
      }
      "npm:@ifi/oh-pi-themes"
      "npm:@ifi/oh-pi-prompts"
      "npm:@ifi/oh-pi-ant-colony"
      {
        source = "npm:@ifi/oh-pi-extensions";
        extensions = [
          "extensions/*.ts"
          "!extensions/custom-footer.ts"
          "!extensions/usage-tracker.ts"
          "!extensions/git-guard.ts"
        ];
      }
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
    keybindings = mkOpt types.attrs { } "Pi keybindings, put under ~/.pi/agent/keybindings.json";
    mcps = mkOpt types.attrs { } "Pi MCPs, put under ~/.pi/agent/mcps.json";
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
      ".pi/agent/keybindings.json".text = builtins.toJSON cfg.keybindings;
      ".pi/agent/mcps.json".text = builtins.toJSON cfg.mcps;

      ".pi/agent/extensions/statusline.ts".source = ./extensions/statusline.ts;
      ".pi/agent/extensions/git-guard.ts".source = ./extensions/git-guard.ts;
      ".pi/agent/extensions/wiki-memory.ts".source = ./extensions/wiki-memory.ts;
    };
  };
}
