{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.herdr;
in
{
  options.${namespace}.ai.herdr = {
    enable = mkBoolOpt false "Enable Herdr terminal workspace manager";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.herdr ];

    xdg.configFile."herdr/config.toml".source =
      (pkgs.formats.toml { }).generate "herdr-config.toml" {
        keys = {
          split_vertical = "prefix+\"";
          split_horizontal = "prefix+%";
        };
      };
  };
}
