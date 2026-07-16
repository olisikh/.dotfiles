{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.peekaboo;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.apps.peekaboo = {
    enable = mkBoolOpt false "Enable Peekaboo (macOS CLI and MCP server for screen capture and GUI automation)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "Peekaboo requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.brews = [ {
      name = "steipete/tap/peekaboo";
      trusted = true;
    } ];
  };
}
