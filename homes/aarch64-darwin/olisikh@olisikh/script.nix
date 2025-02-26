{ homeManagerConfig, ... }:
let
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
      echo
      echo "make        : Rebuild dotfiles"
      echo "update      : Update dotfiles"
      echo "generations : List dotfiles generations"
      echo "rollback    : Rollback to previous generation"
      echo "gc          : Nix gc"
      echo "help        : Help"
  }

  # Function to perform 'home make'
  home_make() {
      darwin-rebuild switch --flake ~/.dotfiles --impure "$@"
  }

  # Function to perform 'home update'
  home_update() {
      nix flake update --flake ~/.dotfiles "$@"
  }

  home_list_generations() {
      darwin-rebuild --list-generations "$@"
  }

  home_rollback() {
    gen_id=$(darwin-rebuild --list-generations | fzf | awk '{print $1}')
    if [[ -z ''${gen_id:+x} ]]; then
      echo "No generation selected, rollback aborted."
    else
      darwin-rebuild --switch-generation ''${gen_id}
    fi
  }

  home_gc() {
    nix-store --gc && nix-collect-garbage -d
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
          generations)
                home_list_generations "$@"
              ;;
          rollback)
              home_rollback
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
