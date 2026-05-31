{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.ai.opencode;

  homeDir = config.home.homeDirectory;

  basicConfig = {
    theme = "catppuccin";
    autoupdate = false;
    autoshare = false;
    model = "opencode-go/kimi-k2.6";
    small_model = "opencode-go/deepseek-v4-flash";
    instructions = [
      "${homeDir}/.config/opencode/CAVEMAN.md"
    ];
    agent = {
      plan.prompt = builtins.readFile ./prompts/PLAN.md;
      build.prompt = builtins.readFile ./prompts/BUILD.md;
      general.prompt = builtins.readFile ./prompts/GENERAL.md;
      explore.prompt = builtins.readFile ./prompts/EXPLORE.md;
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

    home = {
      file = {
        ".config/opencode/config.json".text = builtins.toJSON finalConfig;
        ".config/opencode/CAVEMAN.md".text = builtins.readFile ./prompts/CAVEMAN.md;
        ".config/zsh/init.d/opencode.zsh".text =
          # zsh
          ''
            eval "$(opencode completion)"
          '';
      };

      sessionVariables = {
        OPENCODE_CONFIG = "${homeDir}/.config/opencode/config.json";
      };
    };
  };
}
