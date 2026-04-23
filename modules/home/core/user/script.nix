{ config, namespace, homeDirectory, lib }:
let
  inherit (config.${namespace}.core) sops;
  inherit (lib) optionals;
  inherit (lib.${namespace}) pad color;

  dotDir = "${homeDirectory}/.dotfiles";

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
        action = "home_secrets";
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
      sudo darwin-rebuild switch --flake ${dotDir} "$@"

      # Only load yabai scripting addition if required SIP features are disabled
      # yabai needs: Filesystem Protections, Debugging Restrictions (and NVRAM on Apple Silicon)
      if command -v "yabai" >/dev/null 2>&1; then
          # Check if Filesystem Protections and Debugging Restrictions are disabled
          local sip_status
          sip_status=$(csrutil status 2>&1)
          
          # SIP status can be "disabled", "enabled", or "unknown" (when partially disabled)
          # We need to check if the specific required protections are disabled
          if echo "$sip_status" | grep -q "Filesystem Protections: disabled" && \
             echo "$sip_status" | grep -q "Debugging Restrictions: disabled"; then
              sudo yabai --load-sa
          else
              echo "Warning: yabai scripting addition not loaded."
              echo "Required SIP features (Filesystem and Debugging protections) must be disabled."
              echo "See: https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection"
          fi
      fi
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

  home_secrets() {
      check_command sops
      local secrets_file="${homeDirectory}/.config/sops/secrets.yaml"

      mkdir -p "$(dirname "$secrets_file")"

      if [[ ! -s "$secrets_file" ]]; then
          check_command age-keygen

          if [[ -z "$SOPS_AGE_KEY_FILE" || ! -r "$SOPS_AGE_KEY_FILE" ]]; then
              echo "Error: SOPS_AGE_KEY_FILE is missing or unreadable: $SOPS_AGE_KEY_FILE"
              exit 1
          fi

          local recipient
          recipient="$(age-keygen -y "$SOPS_AGE_KEY_FILE")"

          if [[ -z "$recipient" ]]; then
              echo "Error: failed to derive age recipient from $SOPS_AGE_KEY_FILE"
              exit 1
          fi

          echo "Bootstrapping encrypted secrets file at $secrets_file"
          printf '{}\n' > "$secrets_file"
          sops --encrypt --in-place --age "$recipient" "$secrets_file"
      fi

      sops "$secrets_file"

      # echo "Syncing secrets into ~/.config/sops-nix/secrets folder"
      # launchctl kickstart -k gui/$(id -u)/org.nix-community.home.sops-nix
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
