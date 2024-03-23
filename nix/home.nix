{ inputs, pkgs, config, ... }:
let
  user = builtins.getEnv "USER";
  catppuccinFlavour = "mocha";
in
{
  imports = [
    (import ./shell.nix (catppuccinFlavour))
    ./git.nix
    ./neovim.nix
  ];

  home = {
    username = user;
    homeDirectory = "/Users/${user}";

    stateVersion = "22.11";

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs;
      [
        nix-prefetch
        bash
        wget
        (nerdfonts.override {
          fonts = [ "Meslo" "JetBrainsMono" "FiraCode" "Hack" ];
        })
        fd
        fzf
        eza # exa fork, as original package is not maintained
        jq
        mc
        lua
        tmux
        rustup
        luarocks
        tree-sitter
        python3
        docker
        minikube
        kubernetes-helm
        terraform
        yarn
        go
        jdk17
        kafkactl
        # awscli2
        kcat
        bun
        stern # kubectl pod log scraping tool
        htop
        nodejs
        (sbt.override {
          jre = jdk17;
        })
        coursier
        scala

        (pkgs.writeShellScriptBin "home-make" ''
          home-manager switch --flake ~/.dotfiles#${user} --impure
        '')
        (pkgs.writeShellScriptBin "home-update" ''
          nix flake update ~/.dotfiles
        '')
        (pkgs.writeShellScriptBin "home-upgrade" ''
          home-update && home-make
        '')
      ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    file = {
      ".config/alacritty/catppuccin".source = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "alacritty";
        rev = "main";
        sha256 = "sha256-HiIYxTlif5Lbl9BAvPsnXp8WAexL8YuohMDd/eCJVQ8=";
      };

      ".local/share/mc/ini".source = ~/.dotfiles/mc/ini;
      ".local/share/mc/skins".source = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "mc";
        rev = "main";
        sha256 = "sha256-m6MO0Q35YYkTtVqG1v48U7pHcsuPmieDwU2U1ZzQcjo=";
      };

      # # Building this configuration will create a copy of 'dotfiles/screenrc' in
      # # the Nix store. Activating the configuration will then make '~/.screenrc' a
      # # symlink to the Nix store copy.
      # ".screenrc".source = dotfiles/screenrc;

      # # You can also set the file content immediately.
      # ".gradle/gradle.properties".text = ''
      #   org.gradle.console=verbose
      #   org.gradle.daemon.idletimeout=3600000
      # '';
    };

    # You can also manage environment variables but you will have to manually
    # source
    #
    #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #  /etc/profiles/per-user/O.Lisikh/etc/profile.d/hm-session-vars.sh
    #
    # if you don't want to manage your shell through Home Manager.
    sessionVariables = {
      JAVA_HOME = pkgs.jdk17;
      CATPPUCCIN_FLAVOUR = catppuccinFlavour; # still used by nvim lua files
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
  };

  programs.tmux = {
    enable = true;

    extraConfig = ''
      # Set true color
      set -g default-terminal 'tmux-256color'
      set-option -sa terminal-features ',xterm-256color:RGB'

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

      # resize panes
      bind-key -r K resize-pane -U 2
      bind-key -r J resize-pane -D 2
      bind-key -r H resize-pane -L 2
      bind-key -r L resize-pane -R 2
    '';

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
