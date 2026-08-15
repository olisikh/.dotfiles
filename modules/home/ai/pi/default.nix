{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.ai.pi;

  basicConfig = {
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.6-luna";
    defaultThinkingLevel = "max";

    theme = "catppuccin-mocha-void-tools";
    quietStartup = true;

    packages = [
      "npm:pi-ollama-cloud"
      "npm:pi-dynamic-workflows"
      "npm:pi-mcp-adapter"
      "npm:pi-lens"
      "npm:@upstash/context7-pi"
      "npm:@mariozechner/pi-tui"
      "npm:@ifi/pi-plan"
      "npm:@ifi/pi-extension-subagents"
      {
        source = "npm:@ifi/oh-pi-skills";
        skills = [
          "!skills/graphify/**"
          "!skills/improve-codebase-architecture/**"
          "!skills/grill-me/**"
        ];
      }
    ];

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

    # pi would react to "all" steered/follow-up messages at once or "one-at-a-time"
    steeringMode = "all";
    followUpMode = "one-at-a-time";

    # pi has no built-in permission system or MCP (both are opt-in extensions),
    # matching opencode's trust-heavy defaults: keep project trust on "ask".
    defaultProjectTrust = "ask";
  };

  mcpConfig = recursiveUpdate
    {
      settings = {
        toolPrefix = "none";
        directTools = false;
        scriptMode = false;
      };
      mcpServers = {
        exa = {
          url = "https://mcp.exa.ai/mcp";
          auth = false;
          protocolVersion = "legacy";
          httpTransport = "streamable-http";
          directTools = true;
        };
      };
    }
    cfg.mcps;

  finalConfig = recursiveUpdate basicConfig cfg.config;
in
{
  options.${namespace}.ai.pi = {
    enable = mkBoolOpt false "Enable pi terminal coding agent";
    config = mkOpt types.attrs { } "Pi settings attrset merged into the module's base config";
    doubleEscapeWindowMs = mkOpt types.ints.positive 3000 "Milliseconds allowed between Escape presses to abort an active agent";
    keybindings = mkOpt types.attrs { } "Pi keybindings, put under ~/.pi/agent/keybindings.json";
    mcps = mkOpt types.attrs { } "Pi MCP adapter config merged into the default Exa server configuration";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.llm-agents.pi
    ];

    home.sessionVariables.PI_DOUBLE_ESCAPE_WINDOW_MS = toString cfg.doubleEscapeWindowMs;

    home.file = {
      ".pi/agent/settings.json".text = builtins.toJSON finalConfig;
      ".pi-lens/config.json".text = builtins.toJSON {
        widget.visible = false;
        lsp.enabled = true;
      };
      ".pi/agent/keybindings.json".text = builtins.toJSON cfg.keybindings;
      ".pi/agent/mcp.json".text = builtins.toJSON mcpConfig;
      ".pi/agent/themes/catppuccin-mocha.json".source = ./themes/catppuccin-mocha.json;

      ".pi/agent/extensions".source = ./extensions;
      ".pi/agent/themes".source = ./themes;
    };
  };
}
