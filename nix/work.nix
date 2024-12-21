{ pkgs, ... }:
let
  user = "O.Lisikh";
  jdk = pkgs.jdk17;
  scala = pkgs.scala-next;
  homeDir = "/Users/${user}";
in
{
  imports = [
    ./zsh
    ./fzf
    ./zoxide
    ./wezterm
    ./ripgrep
    ./starship
    ./git
    ./nvim
    ./mc
    ./direnv
  ];

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
      nerd-fonts.meslo-lg
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      fd
      eza
      jq
      zoxide
      rustup
      tree-sitter
      luarocks-nix
      docker
      docker-compose
      colima
      qemu
      minikube
      kubernetes-helm
      terraform
      nodejs
      (yarn.override { nodejs = nodejs; })
      go
      jdk
      kafkactl
      awscli2
      kcat
      bun
      stern # kubectl pod log scraping tool
      htop
      pngpaste
      scala
      (sbt.override { jre = jdk; })
      (metals.override { jre = jdk; })
      xdg-utils # open apps from console/neovim
      wezterm
      lazygit
      gnupg # tool for generating GPG keys
      watch
      rover
      (python3.withPackages (ps: with ps; [
        pip
        pytest
        debugpy
      ]))

      (pkgs.writeShellScriptBin "home" ''
        #!/bin/bash

        # Function to display help message
        display_help() {
            echo "Usage: home <command>"
            echo
            echo "Commands:"
            echo "  make     : Rebuild dotfiles"
            echo "  update   : Update dotfiles"
            echo "  upgrade  : Rebuild and updade dotfiles"
            echo "  rollback : Rollback to previous generation (use if things go wrong)"
            echo "  direnv   : Create ~/.envrc file for direnv"
        }

        # Function to perform 'home make'
        home_make() {
            home-manager switch --flake ~/.dotfiles#work --impure
        }

        # Function to perform 'home update'
        home_update() {
            nix flake update ~/.dotfiles
        }

        # Function to perform 'home upgrade'
        home_upgrade() {
            home_update
            home_make
        }

        home_rollback() {
          store_path=$(home-manager generations | fzf | awk '{print $NF}')
          if [[ -z ''${store_path:+x} ]]; then
            echo "No generation selected, rollback aborted."
          else
            $store_path/activate
          fi
        }

        # Main function to handle input and execute corresponding action
        main() {
            case "$1" in
                make)
                    home_make
                    ;;
                update)
                    home_update
                    ;;
                upgrade)
                    home_upgrade
                    ;;
                rollback)
                    home_rollback
                    ;;
                direnv)
                    echo "use_nix" > ~/.envrc
                    ;;
                *)
                    display_help
                    exit 1
                    ;;
            esac
        }

        # Execute main function with provided arguments
        main "$@"
      '')
    ];

    sessionVariables = {
      SCALA_HOME = scala;
      JAVA_HOME = jdk;
      TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = /var/run/docker.sock;
      DOCKER_HOST = "unix://${homeDir}/.colima/default/docker.sock";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
  };
}
