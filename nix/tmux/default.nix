{ theme, themeStyle, ... }: { pkgs, ... }:
{
  home = {
    file = {
      ".config/tmux/themes/tokyonight".source = (pkgs.fetchFromGitHub
        {
          owner = "folke";
          repo = "tokyonight.nvim";
          rev = "main";
          sha256 = "sha256-ItCmSUMMTe8iQeneIJLuWedVXsNgm+FXNtdrrdJ/1oE=";
        } + "/extras/tmux");
    };

    packages = with pkgs; [
      tmux
    ];
  };

  programs.tmux = {
    enable = true;
    clock24 = true;

    extraConfig = ''
      # Set true color
      set -g default-terminal 'tmux-256color'
      set-option -sa terminal-features ',xterm-256color:RGB'

      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'  # underscore colours - needs tmux-3.0

      # change leader key to CTRL+s
      unbind C-b
      set -g prefix C-s
      bind C-s send-prefix
      set -sg escape-time 300
      set -sg repeat-time 500

      # mouse support
      set -g mouse on
      set-window-option -g xterm-keys on

      # act like vim
      setw -g mode-keys vi
      set-window-option -g mode-keys vi

      # open panes in current dir
      bind '"' split-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # Start windows and panes at 1, not 0
      set -g status-position top
      set -g base-index 1
      setw -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      # skip "kill-pane 1? (y/n)" prompt
      bind-key x kill-pane

      # don't exit from tmux when closing a session
      set -g detach-on-destroy off

      unbind r
      bind-key r source-file ~/.config/tmux/tmux.conf; display-message 'Config reloaded!'

      unbind Left
      unbind Down
      unbind Up
      unbind Right

      unbind M-Left
      unbind M-Right

      bind -n M-H previous-window
      bind -n M-L next-window

      bind-key -n C-S-Left swap-window -t -1
      bind-key -n C-S-Right swap-window -t +1

      # resize panes
      bind-key -r K resize-pane -U 2
      bind-key -r J resize-pane -D 2
      bind-key -r H resize-pane -L 2
      bind-key -r L resize-pane -R 2

      # install some plugins with tpm as they are slowly updated in Nix
      set -g @plugin 'tmux-plugins/tpm'

      # defaults for tmux status bar, override by themes
      set -g mode-style "fg=#7aa2f7,bg=#3b4261"

      set -g message-style "fg=#7aa2f7,bg=#3b4261"
      set -g message-command-style "fg=#7aa2f7,bg=#3b4261"

      set -g pane-border-style "fg=#3b4261"
      set -g pane-active-border-style "fg=#7aa2f7"

      set -g status "on"
      set -g status-justify "left"

      set -g status-style "fg=#7aa2f7,bg=#16161e"

      set -g status-left-length "100"
      set -g status-right-length "100"

      set -g status-left-style NONE
      set -g status-right-style NONE

      set -g status-left "#[fg=#15161e,bg=#7aa2f7,bold] #W #[fg=#7aa2f7,bg=#16161e,nobold,nounderscore,noitalics]"
      set -g status-right "#{load_full} "

      if-shell '[ "$(tmux show-option -gqv "clock-mode-style")" == "24" ]' {
        set -g status-right "#{load_full} "
      }

      setw -g window-status-activity-style "underscore,fg=#a9b1d6,bg=#16161e"
      setw -g window-status-separator ""
      setw -g window-status-style "NONE,fg=#a9b1d6,bg=#16161e"
      setw -g window-status-format "#[fg=#16161e,bg=#16161e,nobold,nounderscore,noitalics]#[default] #I  #{b:pane_current_path} #[fg=#16161e,bg=#16161e,nobold,nounderscore,noitalics]"
      setw -g window-status-current-format "#[fg=#16161e,bg=#3b4261,nobold,nounderscore,noitalics]#[fg=#7aa2f7,bg=#3b4261,bold] #I  #{b:pane_current_path} #[fg=#3b4261,bg=#16161e,nobold,nounderscore,noitalics]"

      # tmux-plugins/tmux-prefix-highlight support
      set -g @prefix_highlight_output_prefix "#[fg=#e0af68]#[bg=#16161e]#[fg=#16161e]#[bg=#e0af68]"
      set -g @prefix_highlight_output_suffix ""
    '' +

    (if theme == "catppuccin" then
      ''
        # install catppuccin theme and configure
        set -g @plugin 'catppuccin/tmux'

        set -g @catppuccin_flavour "${themeStyle}"

        set -g @catppuccin_window_number_position "left"

        set -g @catppuccin_window_default_fill "number"
        set -g @catppuccin_window_default_text "#{b:pane_current_path}"
        set -g @catppuccin_window_current_fill "number"
        set -g @catppuccin_window_current_text "#{b:pane_current_path}"

        set -g @catppuccin_status_default "on"
        set -g @catppuccin_status_modules_right "load"
        set -g @catppuccin_status_modules_left "application"

        set -g @catppuccin_status_left_separator "█"
        set -g @catppuccin_status_right_separator "█"
        set -g @catppuccin_status_right_separator_inverse "no"
        set -g @catppuccin_status_fill "icon"
        set -g @catppuccin_status_connect_separator "no"
      ''
    else if theme == "tokyonight" then ""
    else "") +

    ''
      # install cpu, batter and load avg
      set -g @plugin 'jamesoff/tmux-loadavg'

      # install utility plugins
      set -g @plugin 'tmux-plugins/tmux-resurrect'
      set -g @plugin 'tmux-plugins/tmux-continuum'
      set -g @continuum-restore 'on'

      set -g @plugin 'tmux-plugins/tmux-sensible'
      set -g @plugin 'tmux-plugins/tmux-yank'
      set -g @plugin 'christoomey/vim-tmux-navigator'

      # automatically install tpm and all plugins
      if "test ! -d ~/.config/tmux/plugins/tpm" \
      "run 'git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm && ~/.config/tmux/plugins/tpm/bin/install_plugins'"

      # initialise plugins installed via tpm
      run '~/.config/tmux/plugins/tpm/tpm'
    '';
  };
}
