{ lib, config, namespace, pkgs, ... }:
with lib;
let
  inherit (lib.${namespace}) mkOpt mkBoolOpt;

  cfg = config.${namespace}.codex;
in
{
  options.${namespace}.codex = with types; {
    enable = mkBoolOpt false "Enable codex module";
  };

  config = mkIf cfg.enable {
    programs.codex = {
      enable = true;

      settings = {

      };
    };
  };
}
