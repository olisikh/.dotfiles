{ lib, config, namespace, ... }:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.media.obs;
in
{
  options.${namespace}.media.obs = {
    enable = mkBoolOpt false "Enable obs module";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "obs" ];
  };
}
