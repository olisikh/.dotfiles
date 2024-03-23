catppuccinFlavour: { pkgs, ... }:
{
  home = {
    file = {
      ".config/alacritty/catppuccin".source = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "alacritty";
        rev = "main";
        sha256 = "sha256-HiIYxTlif5Lbl9BAvPsnXp8WAexL8YuohMDd/eCJVQ8=";
      };
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
          style = "Medium";
        };

        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };

        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Medium Italic";
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

      import = [
        "~/.config/alacritty/catppuccin/catppuccin-${catppuccinFlavour}.toml"
      ];
    };
  };
}
