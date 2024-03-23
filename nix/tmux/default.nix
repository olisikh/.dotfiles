{ catppuccinFlavour, ... }: { pkgs, ... }:
{

  home.packages = with pkgs; [
    tmux
  ];

  programs.tmux = {
    enable = true;

    extraConfig = builtins.readFile ./tmux.conf;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavour "${catppuccinFlavour}"

          set -g @catppuccin_window_left_separator ""
          set -g @catppuccin_window_right_separator " "
          set -g @catppuccin_window_middle_separator "█ "
          set -g @catppuccin_window_number_position "left"

          set -g @catppuccin_window_default_fill "number"
          set -g @catppuccin_window_default_text "#{b:pane_current_path}"
          set -g @catppuccin_window_current_fill "number"
          set -g @catppuccin_window_current_text "#{b:pane_current_path}"

          set -g @catppuccin_status_default "off"
          set -g @catppuccin_status_modules "directory application session"
          # uncomment once plugin is updated
          # set -g @catppuccin_status_modules_right "directory application session"
          set -g @catppuccin_status_left_separator  " "
          set -g @catppuccin_status_right_separator ""
          set -g @catppuccin_status_right_separator_inverse "no"
          set -g @catppuccin_status_fill "icon"
          set -g @catppuccin_status_connect_separator "no"

          set -g @catppuccin_directory_text "#{pane_current_path}"
        '';
      }
      vim-tmux-navigator
      yank
    ];
  };
}
