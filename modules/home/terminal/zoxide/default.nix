{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.terminal.zoxide;
in
{

  options.${namespace}.terminal.zoxide = {
    enable = mkBoolOpt false "Enable zoxide program";
  };

  config = mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
