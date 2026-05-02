{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;

  cfg = config.${namespace}.core.user;

  username = config.snowfallorg.user.name;
  homeDirectory = config.snowfallorg.user.home.directory;
  userScripts = [
    "jetbrains-plugin-id"
    "lib.sh"
    "nix-build"
    "nix-dev"
    "nix-gc"
    "nix-gens"
    "nix-rollback"
    "nix-secrets"
    "nix-tpl"
    "nix-update"
  ];
in
{
  options.${namespace}.core.user = with types; {
    enable = mkBoolOpt false "Enable user programs";
    name = mkOpt str "Oleksii Lisikh" "Name of the user";
    homeDirectory = mkOpt str defaultHomeDir "The user's home directory";

    sessionVariables = mkOpt types.attrs { } "Extra home-manager session variables for the user";

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Home manager packages to enable";
    };
  };

  config = mkIf cfg.enable {
    home = {
      inherit username homeDirectory;
      inherit (cfg) sessionVariables;

      # don't ever change the stateversion value, it will break the state
      stateVersion = "25.05";

      sessionPath = [ "$HOME/.local/bin" ];

      file = lib.listToAttrs (map
        (script: {
          name = ".local/bin/${script}";
          value = {
            source = ./scripts/${script};
            executable = script != "lib.sh";
          };
        })
        userScripts);

      packages = with pkgs; [
        nix-prefetch
        nix-search-cli

        (writeShellScriptBin "home" (import ./script.nix {
          inherit config namespace lib homeDirectory;
        }))
      ] ++ cfg.packages;
    };

    # Ensure HM GUI apps are linked to ~/Applications on macOS.
    targets.darwin.linkApps = {
      enable = true;
      directory = "Applications/Home Manager Apps";
    };

    home.activation.linkDarwinApplications = lib.mkAfter # bash
      ''
        # Keep HM apps visible to Spotlight/Raycast launchers by creating Finder aliases in ~/Applications
        # and re-registering them with LaunchServices.
        src_dir="$HOME/Applications/Home Manager Apps"
        dst_dir="$HOME/Applications"
        lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

        mkdir -p "$dst_dir"
        if [ -d "$src_dir" ]; then
          for app in "$src_dir"/*.app; do
            [ -e "$app" ] || continue

            app_name="$(basename "$app")"
            dst="$dst_dir/$app_name"

            # Avoid deleting a real app bundle placed manually in ~/Applications.
            if [ -d "$dst" ] && [ ! -L "$dst" ]; then
              continue
            fi

            if [ -L "$dst" ] || [ -f "$dst" ]; then
              rm -f "$dst"
            fi

            source_app="$app"
            if [ -L "$app" ]; then
              source_app="$(readlink "$app")"
            fi

            ${pkgs.mkalias}/bin/mkalias "$source_app" "$dst"
            "$lsregister" -f "$dst" >/dev/null 2>&1 || true
          done
        fi
      '';

    # let home manager install and manage itself.
    programs.home-manager.enable = true;
  };
}
