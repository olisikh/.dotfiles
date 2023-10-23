{ config, pkgs, lib, ... }:
let
  user = builtins.getEnv "USER";
  homeDir = "/Users/${user}";
  catppuccinFlavour = "macchiato";
in
{
  home = {
    username = user;
    homeDirectory = homeDir;

    stateVersion = "22.11";

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
      nix-prefetch
      direnv # use nix-shell whenever using cd and default.nix or shell.nix is in path
      bash
      git
      (nerdfonts.override { fonts = [ "Hack" ]; })
      fd
      fzf
      zoxide
      ripgrep
      eza # exa fork, as original package is not maintained
      mc
      lua
      tmux
      rustup
      luarocks
      python3
      thefuck
      docker
      docker-machine
      minikube
      kubernetes-helm
      awscli2
      yarn
      go
      coursier
      jdk11
      kafkactl
      awscli2
      kcat
      bun
      stern # kubectl pod log scraping tool
      htop
      nodejs
      (sbt.override { jre = jdk11; })
      scala

      # # You can also create simple shell scripts directly inside your
      # # configuration. For example, this adds a command 'my-hello' to your
      # # environment:
      # (pkgs.writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')

      (pkgs.writeShellScriptBin "mkhome" ''
        nix flake update ${homeDir}/.dotfiles && \
          home-manager switch --flake ${homeDir}/.dotfiles#${user} --impure
      '')
    ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    file = {
      ".antidote".source = pkgs.fetchFromGitHub {
        owner = "mattmc3";
        repo = "antidote";
        rev = "v1.8.6";
        sha256 = "sha256-CcWEXvz1TB6LFu9qvkVB1LJsa68grK16VqjUTiuVG/c=";
      };

      ".zsh".source = "${homeDir}/.dotfiles/zsh/.zsh";
      ".zshrc".source = "${homeDir}/.dotfiles/zsh/.zshrc";
      ".zsh_plugins.txt".source = "${homeDir}/.dotfiles/zsh/.zsh_plugins.txt";

      ".config/nvim".source = "${homeDir}/.dotfiles/nvim";

      ".config/alacritty/catppuccin".source = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "alacritty";
        rev = "main";
        sha256 = "sha256-w9XVtEe7TqzxxGUCDUR9BFkzLZjG8XrplXJ3lX6f+x0=";
      };

      ".local/share/mc/ini".source = "${homeDir}/.dotfiles/mc/ini";
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
      JAVA_HOME = pkgs.jdk11;
      CATPPUCCIN_FLAVOUR = catppuccinFlavour; # still used by nvim lua files
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;

    initExtra = ''
      source ${homeDir}/.zsh/catppuccin-${catppuccinFlavour}.zsh
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

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

  programs.neovim = {
    enable = true;
    viAlias = false;
    vimAlias = true;
  };

  programs.tmux = {
    enable = true;

    extraConfig = ''
      # Set true color
      set -g default-terminal 'xterm-256color'
      set -as terminal-overrides ',xterm*:Tc:sitm=\E[3m'

      set -g mouse on
      set-window-option -g xterm-keys on

      unbind Left
      unbind Down
      unbind Up
      unbind Right

      unbind M-Left
      unbind M-Right


      # change leader key to CTRL+s
      unbind C-b
      set -g prefix C-s
      bind C-s send-prefix

      set -sg escape-time 300
      set -sg repeat-time 500

      # Start windows and panes at 1, not 0
      set -g status-position top
      set -g base-index 1
      setw -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      bind-key x kill-pane # skip "kill-pane 1? (y/n)" prompt
      set -g detach-on-destroy off  # don't exit from tmux when closing a session

      unbind r
      bind-key r source-file ~/.tmux.conf; display-message 'Config reloaded!'

      bind -n M-H previous-window
      bind -n M-L next-window

      # resize panes
      bind-key -r K resize-pane -U 2
      bind-key -r J resize-pane -D 2
      bind-key -r H resize-pane -L 2
      bind-key -r L resize-pane -R 2

      # act like vim
      setw -g mode-keys vi

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # open panes in current dir
      bind '"' split-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
    '';

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavour ${catppuccinFlavour}
        '';
      }
      sensible
      vim-tmux-navigator
      yank
    ];
  };

  programs.alacritty = {
    enable = true;
  };

  programs.git = {
    enable = true;
    userName = "Oleksii Lisikh";
    userEmail = "alisiikh@gmail.com";

    extraConfig = {
      core = {
        autocrlf = "input";
        excludesfile = "${homeDir}/.gitignore_global";
      };

      submodule = {
        recurse = true;
      };

      init = {
        defaultBranch = "main";
      };
    };
  };

  xdg.configFile = {
    "alacritty/alacritty.yml".source = ./alacritty/alacritty.yml;
    "starship.toml".source = ./starship/starship.toml;
  };
}


