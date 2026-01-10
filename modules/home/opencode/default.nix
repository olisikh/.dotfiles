{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.opencode;
in
{
  options.${namespace}.opencode = {
    enable = mkBoolOpt false "Enable OpenCode program";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;

      settings = {
        theme = "catppuccin";
        autoupdate = false;
        autoshare = false;

        agent = {
          plan = {
            temperature = 0.1;
          };
          build = {
            temperature = 0.1;
          };
        };
      };
    };
  };
}
