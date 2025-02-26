{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.mc;
in
{
  options.${namespace}.mc = {
    enable = mkBoolOpt false "Enable mc program";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        mc
      ];

      file = {
        ".local/share/mc/ini".source = ./mc.ini;

        ".local/share/mc/skins".source = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "mc";
          rev = "main";
          sha256 = "sha256-m6MO0Q35YYkTtVqG1v48U7pHcsuPmieDwU2U1ZzQcjo=";
        };
      };
    };
  };
}
