{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  inherit (lib.${namespace}.zsh) mkLate;

  cfg = config.${namespace}.ai.opencode;

  homeDir = config.home.homeDirectory;

  basicSettings = {
    model = "openai-codex/gpt-5.6-sol";
    small_model = "openai-codex/gpt-5.6-luna";
    autoupdate = false;
    share = "manual";
    formatter = true;
    lsp = true;
    snapshot = true;
    compaction = {
      auto = true;
      prune = false;
      reserved = 10000;
    };

    provider = {
      ollama-cloud = {
        models = {
          "deepseek-v4-flash" = {
            options = {
              reasoningEffort = "max";
            };
          };
        };
      };

      openai = {
        models = {
          "gpt-5.6-sol" = {
            options = {
              reasoningEffort = "high";
            };
          };
          "gpt-5.6-luna" = {
            options = {
              reasoningEffort = "max";
            };
          };
        };

        # HACK: temporary fix for headers response timeout issue with OpenAI API:
        # https://github.com/anomalyco/opencode/issues/29548
        options = {
          headerTimeout = false;
        };
      };
    };

    instructions = [
      "~/.opencode/skills/wiki-manager/SKILL.md"
    ];
    permission = {
      "*" = "ask";
      read = "allow";
      glob = "allow";
      grep = "allow";
      list = "allow";
      skill = "allow";
      webfetch = "allow";
      websearch = "allow";
      lsp = "allow";
      todowrite = "allow";
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
      edit = "ask";
      external_directory = {
        "~/.agents/**" = "allow";
        "~/.config/llm-wiki/**" = "allow";
        "~/.config/opencode/**" = "allow";
        "~/.llm-wiki/**" = "allow";
      };
      task = "ask";
      question = "allow";
      doom_loop = "ask";
    };
    agent = {
      plan = {
        prompt = "${homeDir}/.config/opencode/prompts/plan.md";
        temperature = 0.1;
        permission = {
          edit = "deny";
          bash = {
            "*" = "ask";
            "git status*" = "allow";
            "git log*" = "allow";
            "git diff*" = "allow";
            "git branch*" = "allow";
            "git remote*" = "allow";
            "git show*" = "allow";
          };
          task = "allow";
          webfetch = "allow";
          websearch = "allow";
        };
      };
      build.prompt = "${homeDir}/.config/opencode/prompts/build.md";
      general = {
        prompt = "${homeDir}/.config/opencode/prompts/general.md";
        temperature = 0.2;
      };
      explore = {
        prompt = "${homeDir}/.config/opencode/prompts/explore.md";
        temperature = 0.1;
        permission = {
          edit = "deny";
          bash = "ask";
        };
      };
    };
    mcp = {
      context7 = {
        type = "remote";
        url = "https://mcp.context7.com/mcp";
        enabled = true;
      };
      gh_grep = {
        type = "remote";
        url = "https://mcp.grep.app";
        enabled = true;
      };
    };
    watcher = {
      ignore = [
        "node_modules/**"
        "dist/**"
        "build/**"
        ".git/**"
        ".direnv/**"
        ".devenv/**"
        "result/**"
        "result-*/**"
        "*.lock"
      ];
    };
  };

  finalSettings = lib.recursiveUpdate basicSettings cfg.settings;
in
{
  options.${namespace}.ai.opencode = {
    enable = mkBoolOpt false "Enable OpenCode program";
    settings = mkOpt types.attrs { } "OpenCode settings merged into the module's base config";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = pkgs.llm-agents.opencode;
      settings = finalSettings;
      tui = {
        theme = "catppuccin";
        mouse = true;
        diff_style = "auto";
      };
    };

    programs.zsh.initContent = mkLate
      # zsh
      ''
        eval "$(opencode completion)"
      '';

    home.file = {
      ".config/llm-wiki/config.json".text = builtins.toJSON {
        hub_path = "~/.llm-wiki/hub";
      };
    };
  };
}
