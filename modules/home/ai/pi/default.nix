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
    quietStartup = true;

    packages = [
      "npm:pi-ollama-cloud"
      "@quintinshaw/pi-dynamic-workflows"
      "npm:pi-mcp-adapter"
      "npm:pi-subagents"
      "npm:pi-lens"
      "npm:@vigolium/piolium"
      "npm:@gotgenes/pi-permission-system"
      "npm:pi-rtk-optimizer"
      "npm:pi-title-renamer"
      {
        source = "git:github.com/olisikh/pi-extensions";
        extensions = [
          "packages/pi-plan-mode/src/index.ts"
          "packages/pi-goal/src/index.ts"
        ];
      }
      "npm:context-mode"
      "git:github.com/DietrichGebert/ponytail"
      "git:github.com/olisikh/pi-double-esc"
      "npm:@upstash/context7-pi"
      "npm:@juicesharp/rpiv-todo"
      "npm:@juicesharp/rpiv-ask-user-question"
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

    # pi would react to "all" steered/follow-up messages "all" at once or "one-at-a-time"
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

  permissionConfig = recursiveUpdate
    {
      "$schema" = "https://raw.githubusercontent.com/gotgenes/pi-packages/main/packages/pi-permission-system/schemas/permissions.schema.json";
      debugLog = false;
      permissionReviewLog = true;
      yoloMode = false;

      permission = {
        "*" = "ask";

        # OpenCode equivalents: glob -> find, list -> ls, todowrite -> todo,
        # question -> ask_user_question, webfetch/websearch -> Exa tools.
        read = "allow";
        find = "allow";
        grep = "allow";
        ls = "allow";
        skill = "allow";
        todo = "allow";
        ask_user_question = "allow";
        plan_mode_question = "allow";
        plan_mode_complete = "allow";
        lsp_diagnostics = "allow";
        lsp_navigation = "allow";
        web_fetch_exa = "allow";
        web_search_exa = "allow";

        edit = "ask";
        subagent = "ask";

        bash = {
          "*" = "ask";
          "git status*" = "allow";
          "git log*" = "allow";
          "git diff*" = "allow";
          "git branch*" = "allow";
          "git remote*" = "allow";
          "git show*" = "allow";
          "git push*" = "ask";
          "git commit*" = "ask";
          "grep *" = "allow";
          "rg *" = "allow";
          "nixfmt*" = "allow";
          "shfmt*" = "allow";
          "nix-build*" = "ask";
        };

        external_directory = {
          "~/.agents/**" = "allow";
          "~/.config/llm-wiki/**" = "allow";
          "~/.config/opencode/**" = "allow";
          "~/notes/50 Knowledge/LLM Wiki/**" = "allow";
        };
      };
    }
    cfg.permissions;
in
{
  options.${namespace}.ai.pi = {
    enable = mkBoolOpt false "Enable pi terminal coding agent";
    config = mkOpt types.attrs { } "Pi settings attrset merged into the module's base config";
    permissions = mkOpt types.attrs { } "Pi permission-system config merged into the module's base policy";
    doubleEscapeWindowMs = mkOpt types.ints.positive 3000 "Milliseconds allowed between Escape presses to abort an active agent";
    workingIndicator = {
      type = mkOpt (types.enum [ "shimmer" "spinner" ]) "shimmer" "Working indicator animation style";
      defaultColor = mkOpt types.str "#cba6f7" "Default hex color for the Pi working indicator";
      rotateColors = mkOpt (types.enum [ "none" "rotate" "rainbow" ]) "none" "Working indicator color animation mode";
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
      PI_WORKING_INDICATOR_ROTATE_COLORS = cfg.workingIndicator.rotateColors;
      PI_WORKING_INDICATOR_COLOR_ROTATION_MS = toString cfg.workingIndicator.colorRotationIntervalMs;
      PI_WORKING_INDICATOR_SHIMMER_INTERVAL_MS = toString cfg.workingIndicator.shimmerIntervalMs;
      PI_WORKING_INDICATOR_SPINNER_INTERVAL_MS = toString cfg.workingIndicator.spinnerIntervalMs;
    };


    home.file = {
      ".pi/agent/settings.json".text = builtins.toJSON finalConfig;
      ".pi/agent/extensions/pi-permission-system/config.json".text = builtins.toJSON permissionConfig;
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
      ".pi/agent/extensions/mode-border.ts".source = ./extensions/mode-border.ts;
      ".pi/agent/extensions/lib/mode-events.ts".source = ./extensions/lib/mode-events.ts;
      ".pi/agent/extensions/lib/mode-border.ts".source = ./extensions/lib/mode-border.ts;
      ".pi/agent/extensions/plan-mode-widget.ts".source = ./extensions/plan-mode-widget.ts;
      ".pi/agent/extensions/working-indicator.ts".source = ./extensions/working-indicator.ts;

      ".pi/agent/themes/catppuccin-mocha.json".source = ./themes/catppuccin-mocha.json;
    };
  };
}
