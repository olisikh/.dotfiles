{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.ai.pi;

  basicConfig = {
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.6-luna";
    defaultThinkingLevel = "max";

    subagents = {
      defaultModel = "openai-codex/gpt-5.6-luna";
      defaultThinking = "max";
      modelScope = {
        enforce = true;
        allow = [ "openai-codex/gpt-5.6-luna" ];
      };
      agentOverrides = {
        scout = { thinking = "max"; };
        researcher = { thinking = "max"; };
        worker = { thinking = "max"; };
        reviewer = { thinking = "max"; };
        oracle = { thinking = "max"; };
        delegate = { thinking = "max"; };
      };
    };

    theme = "catppuccin-mocha";
    quietStartup = true;
    npmCommand = [ "npm" ];

    packages = [
      "npm:pi-ollama-cloud"
      "@quintinshaw/pi-dynamic-workflows"
      "npm:pi-mcp-adapter"
      "npm:pi-subagents"
      "npm:pi-lens"
      "npm:@vigolium/piolium"
      "npm:@gotgenes/pi-permission-system"
      "npm:pi-rtk-optimizer"
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
        toolPrefix = "mcp";
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
          directTools = true;
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

        read = "allow";
        find = "allow";
        head = "allow";
        tail = "allow";
        grep = "allow";
        ls = "allow";
        skill = "allow";
        todo = "allow";
        "ctx_*" = "allow";
        "ast_grep_*" = "allow";
        "lens_*" = "allow";
        "lsp_*" = "allow";
        module_report = "allow";
        project_report = "allow";
        read_enclosing = "allow";
        read_symbol = "allow";
        symbol_search = "allow";
        contact_supervisor = "allow";
        ask_user_question = "allow";
        plan_mode_question = "allow";
        plan_mode_complete = "allow";
        "subagent_*" = "allow";

        "mcp__context-mode*" = "allow";
        "mcp__exa*" = "allow";

        subagent = "allow";

        bash = {
          "*" = "ask";

          "git status*" = "allow";
          "git log*" = "allow";
          "git diff*" = "allow";
          "git branch*" = "allow";
          "git remote*" = "allow";
          "git show*" = "allow";
          "git check-ignore*" = "allow";
          "git ls-files*" = "allow";
          "strings *" = "allow";
          "grep *" = "allow";
          "pgrep *" = "allow";
          "ps *" = "allow";
          "awk *" = "allow";
          "for *" = "allow";
          "while *" = "allow";
          "if *" = "allow";
          "test *" = "allow";
          "tr *" = "allow";
          "exit *" = "allow";
          "cat *" = "allow";
          "printf *" = "allow";
          "read *" = "allow";
          "readlink *" = "allow";
          "echo *" = "allow";
          "sort *" = "allow";
          "head *" = "allow";
          "tail *" = "allow";
          "ls *" = "allow";
          "rg *" = "allow";
          "wc *" = "allow";
          "find *" = "allow";
          "cd *" = "allow";
          "pwd" = "allow";
          "sed *" = "allow";
          "true" = "allow";
          "false" = "allow";
          "dirname *" = "allow";
          "which *" = "allow";
          "whoami" = "allow";
          "set *" = "allow";
          "trap *" = "allow";
          "command *" = "allow";
          "nixfmt*" = "allow";
          "jq *" = "allow";
          "id *" = "allow";
          "shfmt*" = "allow";
          "qmd *" = "allow";
        };

        external_directory = {
          "~/.agents/**" = "allow";
          "~/.pi/**" = "allow";
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
      pkgs.${namespace}.qmd
    ];

    home.sessionVariables = {
      LLM_NOTES_ROOT = "${config.home.homeDirectory}/notes";
      LLM_NOTES_QMD_COLLECTION = "notes";
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
      ".pi/agent/themes/catppuccin-mocha.json".source = ./themes/catppuccin-mocha.json;

      ".pi/agent/APPEND_SYSTEM.md".source = ./prompts/brain-policy.md;

      ".pi/agent/keybindings.json".text = builtins.toJSON cfg.keybindings;
      ".pi/agent/mcp.json".text = builtins.toJSON mcpConfig;

      ".pi-lens/config.json".text = builtins.toJSON {
        widget.visible = false;
        lsp.enabled = true;
      };
      ".pi/agent/extensions/pi-permission-system/config.json".text = builtins.toJSON permissionConfig;
      ".pi/agent/extensions/subagent/config.json".text = builtins.toJSON {
        asyncByDefault = true;
        defaultSubagentContext = "fresh";
      };
      ".pi/agent/extensions/statusline.ts".source = ./extensions/statusline.ts;
      ".pi/agent/extensions/welcome.ts".source = ./extensions/welcome.ts;
      ".pi/agent/extensions/built-in-tool-renderer.ts".source = ./extensions/built-in-tool-renderer.ts;
      ".pi/agent/extensions/wiki-memory.ts".source = ./extensions/wiki-memory.ts;
      ".pi/agent/extensions/mode-border.ts".source = ./extensions/mode-border.ts;
      ".pi/agent/extensions/lib/mode-events.ts".source = ./extensions/lib/mode-events.ts;
      ".pi/agent/extensions/lib/mode-border.ts".source = ./extensions/lib/mode-border.ts;
      ".pi/agent/extensions/plan-mode-widget.ts".source = ./extensions/plan-mode-widget.ts;
      ".pi/agent/extensions/working-indicator.ts".source = ./extensions/working-indicator.ts;
      ".pi/agent/extensions/yolo-mode.ts".source = ./extensions/yolo-mode.ts;
    };
  };
}
