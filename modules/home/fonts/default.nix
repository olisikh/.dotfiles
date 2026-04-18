{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.fonts;
in
{
  options.${namespace}.fonts = {
    enable = mkBoolOpt false "Enable fonts";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];
  };
}
