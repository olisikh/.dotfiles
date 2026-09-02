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

    # Visible borders and structure: frame split panes, label panes with
    # their agent name in the border, and separate sidebar entries.
    ui = {
      pane_borders = true;
      pane_outer_borders = true;
      pane_gaps = true;
      show_agent_labels_on_pane_borders = true;

      sidebar = {
        agents = {
          row_gap = 1;
        };
        spaces = {
          row_gap = 1;
        };
      };
    };

    # Catppuccin Mocha tokens: pin the pane area to base, frame the left
    # bar with a darker mantle background, and brighten border/separator
    # lines so surfaces read as distinct. surface_dim is the sidebar's
    # right-edge separator and section-divider color — herdr's catppuccin
    # theme sets it to the background color itself, making the sidebar
    # look borderless, so override it with a visible gray.
    theme.custom = {
      panel_bg = "#1e1e2e";
      sidebar_bg = "#181825";
      surface_dim = "#6c7086";
      overlay0 = "#7f849c";
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
