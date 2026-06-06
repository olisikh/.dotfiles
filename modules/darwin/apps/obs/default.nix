{ lib, config, namespace, ... }:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.obs;
in
{
  options.${namespace}.apps.obs = {
    enable = mkBoolOpt false "Enable obs module";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "obs" ];
  };
}
