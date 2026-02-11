{ config, lib, pkgs, namespace, inputs, ... }:

let
  cfg = config.${namespace}.intellij-idea;

  inherit (inputs.nix-jetbrains-plugins.lib) buildIdeWithPlugins;

  ideaPkg =
    if cfg.edition == "oss" then pkgs.jetbrains.idea-oss
    else pkgs.jetbrains.idea;
in
{
  options.${namespace}.intellij-idea = {
    enable = lib.mkEnableOption "IntelliJ IDEA (JetBrains) with plugins baked in";

    edition = lib.mkOption {
      type = lib.types.enum [ "ultimate" "oss" ];
      default = "ultimate";
      description = "Which IntelliJ IDEA package to install.";
    };

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        JetBrains Marketplace *Plugin ID* strings (NOT github repos).
        You can find “Plugin ID” at the bottom of each Marketplace plugin page.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        (buildIdeWithPlugins pkgs ideaPkg cfg.plugins)
      ];

      file.".ideavimrc".source = ./ideavimrc;
    };
  };
}
