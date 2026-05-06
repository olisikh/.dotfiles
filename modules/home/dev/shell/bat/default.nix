{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.shell.bat;

  catppuccinBat = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "bat";
    rev = "6810349b28055dce54076712fc05fc68da4b8ec0";
    hash = "sha256-lJapSgRVENTrbmpVyn+UQabC9fpV1G1e+CdlJ090uvg=";
  };
in
{
  options.${namespace}.dev.shell.bat = {
    enable = mkBoolOpt false "Enable bat (cat clone with syntax highlighting and git integration)";
  };

  config = mkIf cfg.enable {
    programs.bat = {
      enable = true;
      config = {
        theme = "Catppuccin Mocha";
      };
      themes = {
        "Catppuccin Mocha" = {
          src = catppuccinBat;
          file = "themes/Catppuccin Mocha.tmTheme";
        };
      };
    };
  };
}
