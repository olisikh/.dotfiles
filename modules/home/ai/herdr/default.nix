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
  herdrHermesPlugin = pkgs.runCommand "herdr-agent-state-hermes-plugin" { } ''
    cp -R ${herdrPackage}/share/herdr/integrations/hermes/. "$out"
  '';
  herdrPiPlugin = "${pkgs.llm-agents.herdr}/share/herdr/integrations/pi/herdr-agent-state.ts";

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

      # This direct path is what `herdr integration status` checks. It can
      # coexist with the separate Nix-managed olisikh extension directory.
      ".pi/agent/extensions/herdr-agent-state.ts".source = herdrPiPlugin;
    };

    # Hermes owns the Nix-managed symlink lifecycle for plugins, including
    # cleanup when this integration is later removed.
    ${namespace}.ai.hermes.extraPlugins = [ herdrHermesPlugin ];
  };
}
