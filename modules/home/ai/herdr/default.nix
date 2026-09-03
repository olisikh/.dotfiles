{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  toToml = (pkgs.formats.toml { }).generate;

  cfg = config.${namespace}.ai.herdr;

  herdrConfig = {
    keys = {
      split_vertical = "prefix+\"";
      split_horizontal = "prefix+%";
    };

    ui = {
      pane_borders = true;
      pane_outer_borders = true;
      pane_gaps = true;
      show_agent_labels_on_pane_borders = true;
    };
  };
in
{
  options.${namespace}.ai.herdr = {
    enable = mkBoolOpt false "Enable Herdr terminal workspace manager";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.herdr ];

    home.file = {
      ".config/herdr/config.toml".source = toToml "herdr-config.toml" herdrConfig;
    };
  };
}
