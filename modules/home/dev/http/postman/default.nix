{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.http.postman;
in
{
  options.${namespace}.dev.http.postman = {
    enable = mkBoolOpt false "Enable postman";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      postman
    ];
  };
}
