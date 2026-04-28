{ config, lib, pkgs, namespace, inputs, ... }:

let
  cfg = config.${namespace}.editor.android-studio;

  inherit (inputs.nix-jetbrains-plugins.lib) pluginsForIde;

  defaultConfigVersion = lib.versions.majorMinor pkgs.android-studio.version;

  configDir = "Library/Application Support/Google/AndroidStudio${cfg.configVersion}";

  resolvedPlugins = pluginsForIde pkgs pkgs.android-studio cfg.plugins;

  normalizePlugin = pluginId: pluginDrv:
    if lib.hasSuffix ".jar" pluginDrv.outPath then
      pkgs.runCommand "android-studio-plugin-${lib.strings.sanitizeDerivationName pluginId}" { } ''
        mkdir -p "$out/lib"
        ln -s ${pluginDrv} "$out/lib/$(basename ${pluginDrv})"
      ''
    else
      pluginDrv;

  pluginFiles = lib.mapAttrs'
    (
      pluginId: pluginDrv:
        lib.nameValuePair "${configDir}/plugins/nix-${pluginId}" {
          source = normalizePlugin pluginId pluginDrv;
        }
    )
    resolvedPlugins;
in
{
  options.${namespace}.editor.android-studio = {
    enable = lib.mkEnableOption "Android Studio plugins and config";

    configVersion = lib.mkOption {
      type = lib.types.str;
      default = defaultConfigVersion;
      description = "Android Studio major.minor config directory version, e.g. 2025.3.";
    };

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        JetBrains Marketplace *Plugin ID* strings (NOT github repos).
        These are resolved for Android Studio and linked into its macOS plugins directory.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = pluginFiles;
  };
}
