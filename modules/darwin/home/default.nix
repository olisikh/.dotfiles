{ lib, config, namespace, options, pkgs, ... }:
with lib;
let
  inherit (lib.${namespace}) mkOpt;

  user = config.${namespace}.user;
in
{
  options.${namespace}.home = with types; {
    file = mkOpt attrs { } "A set of files to be managed by home-manager's <option>home.file</option>.";
    configFile =
      mkOpt attrs { }
        "A set of files to be managed by home-manager's <option>xdg.configFile</option>.";
    extraOptions = mkOpt attrs { } "Options to pass directly to home-manager.";
    homeConfig = mkOpt attrs { } "Final config for home-manager.";
  };

  config = {
    olisikh.home.extraOptions = {
      home.stateVersion = mkDefault "25.05";
      home.file = mkAliasDefinitions options.${namespace}.home.file;
      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions options.${namespace}.home.configFile;
    };

    snowfallorg.users.${user.name}.home.config = mkAliasDefinitions options.${namespace}.home.extraOptions;

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
    };
  };
}
