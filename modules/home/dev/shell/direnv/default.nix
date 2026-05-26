{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.shell.direnv;
in
{
  options.${namespace}.dev.shell.direnv = {
    enable = mkBoolOpt false "Enable direnv (environment switcher for directories)";
  };

  config = mkIf cfg.enable {
    programs = {
      direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };

      direnv-instant = {
        enable = false; # NOTE: disabled because of race conditions (unpredictable PATH problem)
        enableZshIntegration = true;
      };
    };
  };
}
