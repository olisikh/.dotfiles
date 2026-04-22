{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.ai.opencode;

  basicConfig = {
    theme = "catppuccin";
    autoupdate = false;
    autoshare = false;
  };

  finalConfig = recursiveUpdate basicConfig cfg.config;
  configFile = pkgs.writeText "opencode-config.json" (builtins.toJSON finalConfig);
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
        ".config/opencode/config.json".source = configFile;
      };

      sessionVariables = {
        OPENCODE_CONFIG = "${config.home.homeDirectory}/.config/opencode/config.json";
      };
    };
  };
}
