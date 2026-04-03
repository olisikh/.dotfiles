{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.opencode;
in
{
  options.${namespace}.opencode = {
    enable = mkBoolOpt false "Enable OpenCode program";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
    };

    home = {
      file = {
        ".config/opencode/oh-my-opencode.jsonc".source = ./config/oh-my-opencode.jsonc;
        ".config/opencode/config.json".source = ./config/opencode.json;
      };

      sessionVariables = {
        OPENCODE_CONFIG = "${config.home.homeDirectory}/.config/opencode/config.json";
      };
    };
  };
}

