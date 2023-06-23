{ config, pkgs, ... }:
let
  user = builtins.getEnv "USER";
  homeDir = "/Users/${user}";
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
      zsh
      alacritty
      git
      (nerdfonts.override { fonts = [ "Hack" ]; })
      starship
      fd
      fzf
      zoxide
      ripgrep
      exa
      bat
      mc
      lua
      neovim
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
      # nodejs
      # (sbt.override { jre = jdk11; })
      # scala

      # # You can also create simple shell scripts directly inside your
      # # configuration. For example, this adds a command 'my-hello' to your
      # # environment:
      # (pkgs.writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')
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
      ".tmux/plugins/tpm".source = pkgs.fetchFromGitHub {
        owner = "tmux-plugins";
        repo = "tpm";
        rev = "v3.1.0";
        sha256 = "sha256-CeI9Wq6tHqV68woE11lIY4cLoNY8XWyXyMHTDmFKJKI=";
      };

      ".zsh".source = "${homeDir}/.dotfiles/zsh/.zsh";
      ".zshrc".source = "${homeDir}/.dotfiles/zsh/.zshrc";
      ".zsh_plugins.txt".source = "${homeDir}/.dotfiles/zsh/.zsh_plugins.txt";
      ".zshenv".source = "${homeDir}/.dotfiles/zsh/.zshenv";

      ".config/nvim".source = "${homeDir}/.dotfiles/nvim";

      ".config/starship.toml".source = "${homeDir}/.dotfiles/starship/starship.toml";

      ".config/alacritty/alacritty.yml".source = "${homeDir}/.dotfiles/alacritty/alacritty.yml";
      ".config/alacritty/catppuccin".source = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "alacritty";
        rev = "main";
        sha256 = "sha256-w9XVtEe7TqzxxGUCDUR9BFkzLZjG8XrplXJ3lX6f+x0=";
      };

      ".config/bat/themes".source = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "bat";
        rev = "main";
        sha256 = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
      };

      ".local/share/mc/ini".source = "${homeDir}/.dotfiles/mc/ini";
      ".local/share/mc/skins".source = pkgs.fetchFromGitHub {
        owner = "catppuccin";
        repo = "mc";
        rev = "main";
        sha256 = "sha256-m6MO0Q35YYkTtVqG1v48U7pHcsuPmieDwU2U1ZzQcjo=";
      };

      # warp terminal
      ".warp".source = "${homeDir}/.dotfiles/warp";

      # tmux
      ".tmux.conf".source = "${homeDir}/.dotfiles/tmux/.tmux.conf";

      # git
      ".gitconfig".source = "${homeDir}/.dotfiles/git/.gitconfig";
      ".gitconfig_global".source = "${homeDir}/.dotfiles/git/.gitignore_global";

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
      # EDITOR = "emacs";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
  };
}

