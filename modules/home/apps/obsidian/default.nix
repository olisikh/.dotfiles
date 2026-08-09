{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.obsidian;

  corePlugins = [
    "file-explorer"
    "global-search"
    "switcher"
    "graph"
    "backlink"
    "canvas"
    "outgoing-link"
    "tag-pane"
    "page-preview"
    "daily-notes"
    { name = "templates"; settings = { folder = "Templates"; }; }
    "note-composer"
    "command-palette"
    "editor-status"
    "bookmarks"
    "outline"
    "word-count"
    "file-recovery"
    "bases"
    "properties"
  ];

  communityPlugins = with pkgs.obsidianPlugins; [
    obsidian-git
    templater-obsidian
    quickadd
    calendar
    periodic-notes
    omnisearch
    cmdr
    table-editor-obsidian
    editing-toolbar
    homepage
    dataview
    obsidian-excalidraw-plugin
    obsidian-icon-folder
    obsidian-minimal-settings
    obsidian-style-settings
  ];
in
{
  options.${namespace}.apps.obsidian.enable = mkBoolOpt false "Manage Obsidian and its notes vault declaratively";

  config = mkIf cfg.enable {
    programs.obsidian = {
      enable = true;
      package = null;
      cli.enable = true;

      vaults.notes = {
        enable = true;
        target = "notes";
        settings = {
          inherit corePlugins communityPlugins;
        };
      };
    };
  };
}
