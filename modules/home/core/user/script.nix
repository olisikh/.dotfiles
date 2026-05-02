{ config, namespace, homeDirectory, lib }:
let
  inherit (config.${namespace}.core) sops;
  inherit (lib) optionals;
  inherit (lib.${namespace}) pad color;

  dotDir = "${homeDirectory}/.dotfiles";

  allCommands = [
    { name = "make"; desc = "Rebuild dotfiles"; action = "nix-build \"$@\""; }
    { name = "update"; desc = "Update dotfiles"; action = "nix-update ${dotDir} \"$@\""; }
    { name = "upgrade"; desc = "Update and rebuild dotfiles"; action = "nix-update ${dotDir} && nix-build"; }
    { name = "tpl"; desc = "Instantiate nix template"; action = "nix-tpl \"$@\""; }
    { name = "dev"; desc = "Run a dev shell"; action = "nix-dev \"$@\""; }
    { name = "generations"; desc = "List dotfiles generations"; action = "nix-gens \"$@\""; }
    { name = "rollback"; desc = "Rollback to previous generation"; action = "nix-rollback \"$@\""; }
    { name = "gc"; desc = "Nix gc"; action = "nix-gc \"$@\""; }
    { name = "help"; desc = "Help"; action = "display_help"; }
  ] ++ (optionals sops.enable
    [
      {
        name = "secrets";
        desc = "Edit secrets";
        action = "nix-secrets \"$@\"";
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
  # Function to display help message
  display_help() {
      echo -e "${helpText}"
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
