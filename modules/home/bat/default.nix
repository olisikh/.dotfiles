{ lib, namespace, config, pkgs, ... }:
let

  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.bat;

  themes = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "bat"; # Bat uses sublime syntax for its themes
    rev = "6810349b28055dce54076712fc05fc68da4b8ec0";
    sha256 = "sha256-lJapSgRVENTrbmpVyn+UQabC9fpV1G1e+CdlJ090uvg=";
  };
in
{
  options.${namespace}.bat = {
    enable = mkBoolOpt false "Enable bat program";
  };

  config = mkIf cfg.enable {
    programs.bat = {
      enable = true;

      config = {
        theme = "catppuccin-mocha";
      };

      themes = {
        catppuccin-mocha = {
          src = themes;
          file = "themes/Catppuccin Mocha.tmTheme";
        };

        catppuccin-latte = {
          src = themes;
          file = "themes/Catppuccin Latte.tmTheme";
        };

        catppuccin-frappe = {
          src = themes;
          file = "themes/Catppuccin Frappe.tmTheme";
        };

        catppuccin-macchiato = {
          src = themes;
          file = "themes/Catppuccin Macchiato.tmTheme";
        };
      };
    };
  };
}
