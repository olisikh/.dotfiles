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
      "npm:pi-subagents"
      "npm:pi-lens"
      "npm:pi-rtk-optimizer"
      "npm:pi-title-renamer"
      "npm:@narumitw/pi-plan-mode"
      "npm:context-mode"
      "git:github.com/DietrichGebert/ponytail"
      "git:github.com/olisikh/pi-double-esc@feat/allow-configuring-hint-position"
      "npm:@upstash/context7-pi"
      "npm:@mariozechner/pi-tui"
      "npm:@juicesharp/rpiv-todo"
      "npm:@juicesharp/rpiv-ask-user-question"
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

    showHardwareCursor = true;

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
        context-mode = {
          command = "context-mode";
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
    workingIndicator = {
      type = mkOpt (types.enum [ "shimmer" "spinner" ]) "shimmer" "Working indicator animation style";
      defaultColor = mkOpt types.str "#cba6f7" "Default hex color for the Pi working indicator";
      rotateColors = mkBoolOpt true "Rotate the working indicator through the Catppuccin palette";
      colorRotationIntervalMs = mkOpt types.ints.positive 2500 "Milliseconds between working indicator palette colors";
      shimmerIntervalMs = mkOpt types.ints.positive 200 "Milliseconds between shimmer frames";
      spinnerIntervalMs = mkOpt types.ints.positive 120 "Milliseconds between spinner frames";
    };
    keybindings = mkOpt types.attrs { } "Pi keybindings, put under ~/.pi/agent/keybindings.json";
    mcps = mkOpt types.attrs { } "Pi MCP adapter config merged into the default Exa server configuration";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.llm-agents.pi
      pkgs.rtk
      pkgs.${namespace}.context-mode
    ];

    home.sessionVariables = {
      PI_DOUBLE_ESC_MS = toString cfg.doubleEscapeWindowMs;
      PI_DOUBLE_ESC_HINT_POSITION = "left";
      PI_WORKING_INDICATOR_TYPE = cfg.workingIndicator.type;
      PI_WORKING_INDICATOR_DEFAULT_COLOR = cfg.workingIndicator.defaultColor;
      PI_WORKING_INDICATOR_ROTATE_COLORS = if cfg.workingIndicator.rotateColors then "1" else "0";
      PI_WORKING_INDICATOR_COLOR_ROTATION_MS = toString cfg.workingIndicator.colorRotationIntervalMs;
      PI_WORKING_INDICATOR_SHIMMER_INTERVAL_MS = toString cfg.workingIndicator.shimmerIntervalMs;
      PI_WORKING_INDICATOR_SPINNER_INTERVAL_MS = toString cfg.workingIndicator.spinnerIntervalMs;
    };


    home.file = {
      ".pi/agent/settings.json".text = builtins.toJSON finalConfig;
      ".pi-lens/config.json".text = builtins.toJSON {
        widget.visible = false;
        lsp.enabled = true;
      };
      ".pi/agent/keybindings.json".text = builtins.toJSON cfg.keybindings;
      ".pi/agent/mcp.json".text = builtins.toJSON mcpConfig;


      ".pi/agent/extensions/statusline.ts".source = ./extensions/statusline.ts;
      ".pi/agent/extensions/welcome.ts".source = ./extensions/welcome.ts;
      ".pi/agent/extensions/built-in-tool-renderer.ts".source = ./extensions/built-in-tool-renderer.ts;
      ".pi/agent/extensions/wiki-memory.ts".source = ./extensions/wiki-memory.ts;
      ".pi/agent/extensions/working-indicator.ts".source = ./extensions/working-indicator.ts;

      ".pi/agent/themes/catppuccin-mocha.json".source = ./themes/catppuccin-mocha.json;
    };
  };
}
