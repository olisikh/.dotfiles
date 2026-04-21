{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.http.bruno;
in
{
  options.${namespace}.dev.http.bruno = {
    enable = mkBoolOpt false "Enable bruno";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      bruno
    ];
  };
}
