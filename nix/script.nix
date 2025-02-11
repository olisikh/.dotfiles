{ homeManagerConfig, ... }:
let
  dotfiles = "~/.dotfiles";
  nixShell =
    # nix
    ''{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativBuildInputs = [
    # build dependencies
  ];
  buildInputs = [
    # runtime dependencies
  ];
}'';
in

# bash
''
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
      echo "  uninstall: Uninstall dotfiles"
      echo "  direnv   : Create ~/.envrc file for direnv"
  }

  # Function to perform 'home make'
  home_make() {
      echo "home make is disabled..."
      # nix build ${dotfiles}#darwinConfigurations.${homeManagerConfig}.config.system && ${dotfiles}/result/sw/bin/darwin-rebuild switch --flake ~/.dotfiles
  }

  # Function to perform 'home update'
  home_update() {
      nix flake update ${dotfiles}
  }

  # Function to perform 'home upgrade'
  home_upgrade() {
      home_update && home_make
  }

  home_rollback() {
    store_path=$(home-manager generations | fzf | awk '{print $NF}')
    if [[ -z ''${store_path:+x} ]]; then
      echo "No generation selected, rollback aborted."
    else
      $store_path/activate
    fi
  }

  home_gc() {
    nix-collect-garbage -d
  }

  home_uninstall() {
    home-manager uninstall
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
          uninstall)
              home_uninstall
              ;;
          direnv)
              echo "use_nix" > ~/.envrc
              ;;
          gc)
              home_gc
              ;;
          mkshell)
              echo "${nixShell}" > shell.nix
              ;;
          *)
              display_help
              exit 1
              ;;
      esac
  }

  # Execute main function with provided arguments
  main "$@"
''
