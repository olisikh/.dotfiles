{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.terminal.ripgrep;
in
{
  options.${namespace}.terminal.ripgrep = {
    enable = mkBoolOpt false "Enable ripgrep program";
  };

  config = mkIf cfg.enable {
    programs.ripgrep = {
      enable = true;
    };
  };
}
