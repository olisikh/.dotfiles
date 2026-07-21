{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  inherit (lib.${namespace}.zsh) mkLate;

  cfg = config.${namespace}.ai.opencode;

  homeDir = config.home.homeDirectory;

  basicConfig = {
    "$schema" = "https://opencode.ai/config.json";
    model = "ollama-cloud/kimi-k2.7-code";
    small_model = "ollama-cloud/deepseek-v4-flash";
    autoupdate = false;
    share = "manual";
    formatter = true;
    lsp = true;
    snapshot = true;
    compaction = {
      auto = true;
      prune = false;
      reserved = 8000;
    };
    instructions = [
      # NOTE: add extra system prompts like SOUL.md, IDENTITY.md, MEMORY.md, or else.
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
        prompt = "${homeDir}/.config/opencode/prompts/PLAN.md";
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
      build.prompt = "${homeDir}/.config/opencode/prompts/BUILD.md";
      general = {
        prompt = "${homeDir}/.config/opencode/prompts/GENERAL.md";
        temperature = 0.2;
      };
      explore = {
        prompt = "${homeDir}/.config/opencode/prompts/EXPLORE.md";
        temperature = 0.1;
        permission = {
          edit = "deny";
          bash = "ask";
        };
      };
    };
    command = {
      commit = {
        description = "Generate a conventional commit message";
        agent = "plan";
        template = "Look at the staged git diff. Write a commit message in Conventional Commits format.\n\nRules:\n- Subject: '<type>(<scope>): <imperative summary>' where type is one of feat, fix, refactor, perf, docs, test, chore, build, ci, style, revert.\n- Subject ≤50 chars when possible, hard cap 72, no trailing period, imperative mood.\n- Scope optional; use it when it clarifies which module changed.\n- Body only if the change's purpose is not obvious. Explain why, not what.\n- Wrap body at 72 chars.\n- Reference issues at the end if any: 'Closes #42'.\n- No AI attribution, no emoji, no 'This commit does...', no first-person.\n\nOutput only the final commit message, nothing else. If no changes are staged, say so.";
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

  finalConfig = recursiveUpdate basicConfig cfg.config;
in
{
  options.${namespace}.ai.opencode = {
    enable = mkBoolOpt false "Enable OpenCode program";
    config = mkOpt types.attrs { } "OpenCode config attrset merged into the module's base config";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
    };

    programs.zsh.initContent = mkLate
      # zsh
      ''
        eval "$(opencode completion)"
      '';

    home = {
      file = {
        ".config/llm-wiki/config.json".text = builtins.toJSON {
          hub_path = "~/.llm-wiki/hub";
        };

        ".config/opencode/opencode.json".text = builtins.toJSON finalConfig;
        ".config/opencode/tui.json".text = builtins.toJSON {
          "$schema" = "https://opencode.ai/tui.json";
          theme = "catppuccin";
          mouse = true;
          diff_style = "auto";
        };
      };
    };
  };
}
