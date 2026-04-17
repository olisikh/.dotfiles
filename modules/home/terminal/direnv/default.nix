{ config, namespace, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.terminal.direnv;
in
{
  options.${namespace}.terminal.direnv = {
    enable = mkBoolOpt false "Enable direnv program";
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
  };
}
