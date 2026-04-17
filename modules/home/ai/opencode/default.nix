{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.opencode;
in
{
  options.${namespace}.ai.opencode = {
    enable = mkBoolOpt false "Enable OpenCode program";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
    };

    home = {
      file = {
        ".config/opencode/config.json".source = ./config/opencode.json;
      };

      sessionVariables = {
        OPENCODE_CONFIG = "${config.home.homeDirectory}/.config/opencode/config.json";
      };
    };
  };
}

