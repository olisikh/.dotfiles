{ config, namespace, home, lib }:
let
  inherit (config.${namespace}) sops;
  inherit (lib) optionals;
  inherit (lib.${namespace}) pad color;

  dotDir = "${home}/.dotfiles";

  allCommands = [
    { name = "make"; desc = "Rebuild dotfiles"; action = "home_make \"$@\""; }
    { name = "update"; desc = "Update dotfiles"; action = "home_update \"$@\""; }
    { name = "upgrade"; desc = "Update and rebuild dotfiles"; action = "home_update && home_make"; }
    { name = "tpl"; desc = "Instantiate nix template"; action = "home_template \"$@\""; }
    { name = "dev"; desc = "Run a dev shell"; action = "home_dev \"$@\""; }
    { name = "generations"; desc = "List dotfiles generations"; action = "home_list_generations \"$@\""; }
    { name = "rollback"; desc = "Rollback to previous generation"; action = "home_rollback"; }
    { name = "gc"; desc = "Nix gc"; action = "home_gc"; }
    { name = "help"; desc = "Help"; action = "display_help"; }
  ] ++ (optionals sops.enable
    [
      {
        name = "secrets";
        desc = "Edit secrets";
        action = "check_command sops && sops ${home}/.config/sops/secrets.yaml";
      }
    ]
  );

  usage = (color.cyan "Usage: ") + "home <command>";

  commandsHeader = color.cyan "Commands:";

  commandsList = builtins.concatStringsSep "\n"
    (map
      (c:
        "  ${color.green (pad c.name 15)}${c.desc}"
      )
      allCommands);

  helpText = ''\n${usage} \n\n${commandsHeader} \n${commandsList}'';

  caseStatements = builtins.concatStringsSep "\n" (map
    (c:
      ''
        ${c.name})
            ${c.action}
            ;;'')
    allCommands);
in
# bash
''
  # Function to check if a command exists
  check_command() {
      if ! command -v "$1" >/dev/null 2>&1; then
          echo "Error: $1 not found. Please install it or enable the corresponding module."
          exit 1
      fi
  }

  # Function to display help message
  display_help() {
      echo -e "${helpText}"
  }

  # Function to perform 'home make'
  home_make() {
      check_command darwin-rebuild
      sudo darwin-rebuild switch --flake ${dotDir} "$@" && sudo yabai --load-sa
  }

  # Function to perform 'home update'
  home_update() {
      check_command nix
      ${dotDir}/scripts/nix-update-gh.sh ${dotDir}
      nix flake update --flake ${dotDir} "$@"
  }

  home_list_generations() {
      check_command darwin-rebuild
      sudo darwin-rebuild --list-generations "$@"
  }

  home_rollback() {
      check_command darwin-rebuild
      check_command fzf
      gen_id=$(sudo darwin-rebuild --list-generations | fzf --tac | awk '{print $1}')
      if [[ -z "$gen_id" ]]; then
          echo "No generation selected, rollback aborted."
      else
          sudo darwin-rebuild --switch-generation "$gen_id"
      fi
  }

  home_gc() {
      nix-store --gc && nix-collect-garbage -d
  }

  home_template() {
      nix flake init -t ${dotDir}#$@
  }

  home_dev() {
      nix develop ${dotDir}#$@ --command zsh
  }

  # Main function to handle input and execute corresponding action
  main() {
      item="$1"
      shift

      case "$item" in
          ${caseStatements}
          *)
              display_help
              exit 1
              ;;
      esac
  }

  # Execute main function with provided arguments
  main "$@"
''
