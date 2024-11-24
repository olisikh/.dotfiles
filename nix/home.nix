{ pkgs, ... }:
let
  user = "olisikh";

  ipkgs = import <nixpkgs> { system = "x86_64-darwin"; };
  bloop = ipkgs.bloop;
  jdk = pkgs.jdk17;
  scala = pkgs.scala-next;
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

  nixpkgs.overlays = [ (import ./overlays) ];

  home = {
    username = user;
    homeDirectory = "/Users/${user}";

    # don't ever change the stateVersion value, it will break the state
    stateVersion = "22.11";

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
      nix-prefetch
      bash
      wget
      (nerdfonts.override {
        fonts = [ "Meslo" "JetBrainsMono" "FiraCode" "Hack" ];
      })
      fd
      eza
      jq
      zoxide
      rustup
      tree-sitter
      luarocks-nix
      docker
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
      nodejs
      scala-next # latest Scala (currently Scala 3 with bundled in Scala CLI)
      (bloop.override { jre = jdk; })
      (sbt.override { jre = jdk; })
      (metals.override { jre = jdk; })
      xdg-utils # open apps from console/neovim
      arc-browser
      wezterm
      lazygit
      watch
      (python3.withPackages (ps: with ps; [
        pip
        pytest
        debugpy
      ]))
      ollama
      obsidian

      (writeShellScriptBin "home" ''
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
            home-manager switch --flake ~/.dotfiles#home --impure "$@"
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
            # shift
            item="$1"
            shift

            case "$item" in
                make)
                    home_make "$@"
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
      SCALA_CLI_POWER = "true";
      JAVA_HOME = jdk;
      OBSIDIAN_VAULT = "~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Notes";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
  };
}
