{ home }:
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
  #!/usr/bin/env bash

  # Function to display help message
  display_help() {
      echo -e "\033[1;36mUsage:\033[0m home <command>"
      echo
      echo -e "\033[1;36mCommands:\033[0m"
      echo -e "  \033[1;32mmake\033[0m         Rebuild dotfiles"
      echo -e "  \033[1;32mupdate\033[0m       Update dotfiles"
      echo -e "  \033[1;32mupgrade\033[0m      Update and rebuild dotfiles"
      echo -e "  \033[1;32mgenerations\033[0m  List dotfiles generations"
      echo -e "  \033[1;32mrollback\033[0m     Rollback to previous generation"
      echo -e "  \033[1;32msecrets\033[0m      Edit secrets"
      echo -e "  \033[1;32mmkshell\033[0m      Create shell.nix file"
      echo -e "  \033[1;32mgc\033[0m           Nix gc"
      echo -e "  \033[1;32mhelp\033[0m         Help"
  }

  # Function to perform 'home make'
  home_make() {
      sudo darwin-rebuild switch --flake "${home}/.dotfiles" "$@"
  }

  # Function to perform 'home update'
  home_update() {
      nix flake update --flake "${home}/.dotfiles" "$@"
  }

  home_list_generations() {
      sudo darwin-rebuild --list-generations "$@"
  }

  home_rollback() {
    gen_id=$(sudo darwin-rebuild --list-generations | fzf --tac | awk '{print $1}')
    if [[ -z ''${gen_id:+x} ]]; then
      echo "No generation selected, rollback aborted."
    else
      sudo darwin-rebuild --switch-generation ''${gen_id}
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
          upgrade)
              home_update && home_make
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
          secrets)
              sops ${home}/.config/sops/secrets.yaml
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
