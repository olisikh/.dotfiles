{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf mkMerge;
  inherit (lib.${namespace}) mkBoolOpt mkStableBinTCC;

  cfg = config.${namespace}.apps.jankyborders;
  svcCfg = config.services.jankyborders;
  userCfg = config.${namespace}.core.user;

  # Stable path on the filesystem that macOS TCC keys on. nix store paths
  # change every rebuild, which silently revokes Accessibility permission for
  # borders. Copying the binary to a fixed path keeps TCC stable across rebuilds.
  stableBin = "/usr/local/bin/borders";

  # Reconstruct the borders arg list the same way nix-darwin's
  # services.jankyborders module does, but with the stable binary as argv[0].
  joinStrings = strings: builtins.concatStringsSep "," strings;

  optionalArg = arg: value:
    if value != null && value != ""
    then
      if lib.isList value
      then lib.map (val: "${arg}=${val}") value
      else [ "${arg}=${value}" ]
    else [];

  bordersArgs =
    optionalArg "width" (toString svcCfg.width)
    ++ optionalArg "hidpi" (if svcCfg.hidpi then "on" else "off")
    ++ optionalArg "active_color" svcCfg.active_color
    ++ optionalArg "inactive_color" svcCfg.inactive_color
    ++ optionalArg "background_color" svcCfg.background_color
    ++ optionalArg "style" svcCfg.style
    ++ optionalArg "blur_radius" (toString svcCfg.blur_radius)
    ++ optionalArg "ax_focus" (if svcCfg.ax_focus then "on" else "off")
    ++ optionalArg "blacklist" (joinStrings svcCfg.blacklist)
    ++ optionalArg "whitelist" (joinStrings svcCfg.whitelist)
    ++ optionalArg "order" svcCfg.order;
in
{
  options.${namespace}.apps.jankyborders = {
    enable = mkBoolOpt false "Enable jankyborders module";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.jankyborders = {
        enable = true;
        active_color = "0xff7aa2f7"; # red: 0xfff7768e, white: 0xffe1e3e4, blue: 0xff7aa2f7
        inactive_color = "0xff494d64";
        width = 10.0;
      };
    }

    ############################################################
    # TCC stability
    #
    # macOS TCC (Accessibility) keys on the binary path. nix store paths
    # change every rebuild, silently revoking permission and causing borders
    # to exit-loop under launchd. Pin the binary to /usr/local/bin/borders
    # so TCC stays stable; only a real version bump re-triggers a re-grant.
    ############################################################
    (mkStableBinTCC {
      src = "${svcCfg.package}/bin/borders";
      dst = stableBin;
      agent = "jankyborders";
      procName = "borders";
      username = userCfg.username;
      permLabel = "Accessibility";
      programArgs = [ stableBin ] ++ bordersArgs;
    })
  ]);
}
