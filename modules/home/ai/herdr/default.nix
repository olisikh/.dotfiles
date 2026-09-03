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

  herdrPackage = pkgs.llm-agents.herdr;
  herdrHermesPlugin = "${herdrPackage}/share/herdr/integrations/hermes";
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
    home.packages = [ herdrPackage ];

    home.file = {
      ".config/herdr/config.toml".source = toToml "herdr-config.toml" herdrConfig;
      ".hermes/plugins/herdr-agent-state/plugin.yaml".source = "${herdrHermesPlugin}/plugin.yaml";
      ".hermes/plugins/herdr-agent-state/__init__.py".source = "${herdrHermesPlugin}/__init__.py";
    };
  };
}
