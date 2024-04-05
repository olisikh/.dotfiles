{ theme, themeStyle, ... }: { pkgs, ... }:
let
  catppuccinPkg = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "bat";
    rev = "main";
    sha256 = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
  };
in
{
  home.packages = with pkgs; [
    bat
  ];

  programs.bat = {
    enable = true;

    themes = {
      catppuccin-mocha = {
        src = catppuccinPkg;
        file = "Catppuccin-mocha.tmTheme";
      };
      catppuccin-macchiato = {
        src = catppuccinPkg;
        file = "Catppuccin-macchiato.tmTheme";
      };
      catppuccin-frappe = {
        src = catppuccinPkg;
        file = "Catppuccin-frappe.tmTheme";
      };
      catppuccin-latte = {
        src = catppuccinPkg;
        file = "Catppuccin-latte.tmTheme";
      };
      eldritch = {
        src = pkgs.fetchFromGitHub {
          owner = "eldritch-theme";
          repo = "bat";
          rev = "main";
          sha256 = "sha256-cNov24rTc8qzNUzT1X1M7wN570PmU6D8JsSd/FO22TY=";
        };
        file = "Eldritch.tmTheme";
      };
    };

    config = {
      theme = if themeStyle != "" then "${theme}-${themeStyle}" else theme;
    };
  };
}
