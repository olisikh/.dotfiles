{ pkgs, ... }:
let
  user = "olisikh";
  theme = "catppuccin";
  themeStyle = "mocha";
  obsidianVault = "~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Notes";
in
{
  imports = (map
    (module: import module {
      themeStyle = themeStyle;
      theme = theme;
    }) [
    ./zsh
    ./git
    ./ripgrep
    ./direnv
    ./starship
    ./zoxide
    ./alacritty
    ./nvim
    ./tmux
    ./fzf
    ./mc
  ]);

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
        eza # exa fork, as original package is not maintained
        jq
        lua
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
        awscli2
        # localstack
        kcat
        bun
        stern # kubectl pod log scraping tool
        htop
        pngpaste
        nodejs
        coursier # install scala via coursier: cs setup

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
            # Extract the store path from the latest generation line
            store_path=$(home-manager generations | sed -n '2p' | awk '{print $NF}')
            # Run the activate script
            $store_path/activate
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
      OBSIDIAN_VAULT = obsidianVault;
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
  };
}
