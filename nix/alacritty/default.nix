{ theme, themeStyle, ... }: { pkgs, ... }:
{
  home = {
    file = {
      ".config/alacritty/catppuccin".source = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "alacritty";
        rev = "main";
        sha256 = "sha256-HiIYxTlif5Lbl9BAvPsnXp8WAexL8YuohMDd/eCJVQ8=";
      };
      ".config/alacritty/tokyonight".source = (pkgs.fetchFromGitHub
        {
          owner = "folke";
          repo = "tokyonight.nvim";
          rev = "main";
          sha256 = "sha256-ItCmSUMMTe8iQeneIJLuWedVXsNgm+FXNtdrrdJ/1oE=";
        } + "/extras/alacritty");
    };

    packages = with pkgs; [
      alacritty
    ];
  };

  programs.alacritty = {
    enable = true;

    settings = {
      env.TERM = "xterm-256color";

      font = {
        size = 14;

        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Light";
        };

        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };

        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Light Italic";
        };

        bold_italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold Italic";
        };
      };

      selection.save_to_clipboard = false;

      window = {
        padding = {
          x = 5;
          y = 5;
        };
      };

      import =
        if theme == "catppuccin" then [ "~/.config/alacritty/catppuccin/catppuccin-${themeStyle}.toml" ]
        else if theme == "tokyonight" then [ "~/.config/alacritty/tokyonight/tokyonight_${themeStyle}.toml" ]
        else [ ];
    };
  };
}
