{ catppuccinFlavour, ... }: { pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
  ];

  programs.bat = {
    enable = true;

    themes = {
      catppuccin = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "main";
          sha256 = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
        };
        file = "Catppuccin-${catppuccinFlavour}.tmTheme";
      };
    };

    config = {
      theme = "catppuccin";
    };
  };
}
