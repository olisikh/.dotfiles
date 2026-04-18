{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.shell.yazi;
in
{
  options.${namespace}.dev.shell.yazi = {
    enable = mkBoolOpt false "Enable yazi (terminal file manager with preview)";
  };

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "yy"; # Legacy default for stateVersion < 26.05
    };
  };
}
