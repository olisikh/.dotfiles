{ lib, namespace, config, pkgs, ... }:
let

  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.bat;

  catppuccinThemes = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "bat"; # Bat uses sublime syntax for its themes
    rev = "699f60fc8ec434574ca7451b444b880430319941";
    sha256 = "sha256-6fWoCH90IGumAMc4buLRWL0N61op+AuMNN9CAR9/OdI=";
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
          src = catppuccinThemes;
          file = "themes/Catppuccin Mocha.tmTheme";
        };

        catppuccin-latte = {
          src = catppuccinThemes;
          file = "themes/Catppuccin Latte.tmTheme";
        };

        catppuccin-frappe = {
          src = catppuccinThemes;
          file = "themes/Catppuccin Frappe.tmTheme";
        };

        catppuccin-macchiato = {
          src = catppuccinThemes;
          file = "themes/Catppuccin Macchiato.tmTheme";
        };
      };
    };
  };
}
