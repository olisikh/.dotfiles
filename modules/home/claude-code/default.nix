{ lib, config, namespace, pkgs, ... }:
with lib;
let
  inherit (lib.${namespace}) mkOpt mkBoolOpt;

  cfg = config.${namespace}.claude-code;
in
{
  options.${namespace}.claude-code = with types; {
    enable = mkBoolOpt false "Enable claude-code program";
  };

  config = mkIf cfg.enable {
    programs.claude-code = {
      enable = true;

      settings = {};
    };
  };
}
