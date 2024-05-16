{ pkgs, ... }:
let
  user = "olisikh";
  themeStyle = "mocha";
in
{
  imports = [
    (import ./zsh {
      inherit themeStyle;
    })
    (import ./fzf {
      inherit themeStyle;
    })
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
      rustc
      tree-sitter
      (lua.withPackages (p: with p; [
        jsregexp
      ]))
      (python3.withPackages (p: with p; [
        pip
        pyaes
        python-jose
        python-dateutil
        tabulate
        localstack
      ]))
      docker
      minikube
      kubernetes-helm
      terraform
      yarn
      go
      jdk17
      kafkactl
      awscli2
      kcat
      bun
      stern # kubectl pod log scraping tool
      htop
      pngpaste
      nodejs
      (sbt.override { jre = jdk17; })
      (metals.override { jre = jdk17; })
      xdg-utils # open apps from console/neovim
      arc-browser
      wezterm

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
            home-manager switch --flake ~/.dotfiles#home --impure
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
      JAVA_HOME = pkgs.jdk17;
      OBSIDIAN_VAULT = "~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Notes";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
  };
}
