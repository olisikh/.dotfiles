{ pkgs, ... }:
let
  user = builtins.getEnv "USER";
  homeDir = "/Users/${user}";
  catppuccinFlavour = "macchiato";

  userName = builtins.getEnv "GIT_NAME";
  userEmail = builtins.getEnv "GIT_EMAIL";
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
      bash
      wget
      (nerdfonts.override { fonts = [ "Meslo" "JetBrainsMono" "FiraCode" "Hack" ]; })
      fd
      fzf
      eza # exa fork, as original package is not maintained
      mc
      lua
      tmux
      rustup
      luarocks
      tree-sitter
      python3
      thefuck
      docker
      minikube
      kubernetes-helm
      terraform
      awscli2
      yarn
      go
      coursier
      jdk17
      kafkactl
      awscli2
      kcat
      bun
      stern # kubectl pod log scraping tool
      htop
      nodejs
      # (sbt.override { jre = jdk17; })
      sbt
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
      ".zsh".source = "${homeDir}/.dotfiles/zsh/.zsh";
      ".envrc".text = "use_nix";

      ".config/nvim".source = "${homeDir}/.dotfiles/nvim";

      ".config/alacritty/catppuccin".source = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "alacritty";
        rev = "main";
        sha256 = "sha256-HiIYxTlif5Lbl9BAvPsnXp8WAexL8YuohMDd/eCJVQ8=";
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
      JAVA_HOME = pkgs.jdk17;
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
    enableAutosuggestions = true;

    initExtraBeforeCompInit = ''
      # init completions
      autoload -U +X bashcompinit && bashcompinit
      autoload -U +X compinit && compinit
    '';

    initExtra = ''
      source ${homeDir}/.zsh/catppuccin-${catppuccinFlavour}.zsh

      eval "$(thefuck --alias)"
      eval "$(kafkactl completion zsh)"

      # Preferred editor for local and remote sessions
      if [[ -n $SSH_CONNECTION ]]; then
        export EDITOR='vi'
      else
        export EDITOR='nvim'
      fi

      # Add rust (cargo) executables
      export CARGO_HOME=${homeDir}/.cargo
      export PATH="$CARGO_HOME/bin:$PATH"

      alias tf=terraform
      alias k=kubectl

      # smart cd
      alias zz="z -"

      # smart ls
      alias ls="exa"
      alias ll="exa -alh"
      alias tree="exa --tree"
      alias cat="bat -pp"

      # overrides for work
      [[ -s "${homeDir}/.zshrc.local" ]] && source "${homeDir}/.zshrc.local"
    '';

    antidote = {
      enable = true;
      useFriendlyNames = true;

      plugins = [
        "rupa/z"
        "zsh-users/zsh-completions"
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-syntax-highlighting"
        "chisui/zsh-nix-shell"
        "nix-community/nix-zsh-completions"
        "ohmyzsh/ohmyzsh path:plugins/git"
      ];
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.ripgrep = {
    enable = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      scala.symbol = " ";
      java.symbol = " ";
      nix_shell.symbol = " ";
      nodejs.symbol = " ";
      golang.symbol = " ";
      rust.symbol = " ";
      docker_context.symbol = " ";
      haskell.symbol = " ";
      elixir.symbol = " ";
      lua.symbol = " ";
      terraform.symbol = " ";
      aws.symbol = "  ";
    };
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
      bind-key r source-file ${homeDir}/.config/tmux/tmux.conf; display-message 'Config reloaded!'

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

    settings = {
      env.TERM = "xterm-256color";

      font = {
        size = 14;

        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };

        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };

        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular Italic";
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
        "${homeDir}/.config/alacritty/catppuccin/catppuccin-${catppuccinFlavour}.toml"
      ];
    };
  };

  programs.git = {
    enable = true;
    userName = userName;
    userEmail = userEmail;

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
}
