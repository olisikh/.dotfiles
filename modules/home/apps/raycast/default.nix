{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.apps.raycast;

  raycastPlugins = pkgs.${namespace}.raycast-plugins;
in
{
  options.${namespace}.apps.raycast = {
    enable = mkBoolOpt false "Enable raycast launcher";
    extensions = mkOpt (types.listOf types.str) [ ] "Raycast extensions to install";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.raycast ];

    home.file = lib.listToAttrs (map
      (pkg:
        let
          ext = raycastPlugins.${pkg};
        in
        {
          name = ".config/raycast/extensions/${lib.getName ext}";
          value = { source = ext; };
        })
      cfg.extensions);
  };
}
