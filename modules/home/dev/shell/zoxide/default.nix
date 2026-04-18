{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.shell.zoxide;
in
{
  options.${namespace}.dev.shell.zoxide = {
    enable = mkBoolOpt false "Enable zoxide (smarter cd command with learning)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.zoxide ];
  };
}
