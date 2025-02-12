{ user }: { pkgs, config, ... }:
{
  system = {
    stateVersion = 6;

    # activationScripts.applications.text =
    #   let
    #     env = pkgs.buildEnv {
    #       name = "system-applications";
    #       paths = config.environment.systemPackages;
    #       pathsToLink = "/Applications";
    #     };
    #   in
    #   pkgs.lib.mkForce ''
    #     # Set up applications.
    #     echo "setting up /Applications..." >&2
    #     rm -rf /Applications/Nix\ Apps
    #     mkdir -p /Applications/Nix\ Apps
    #     find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
    #     while read -r src; do
    #       app_name=$(basename "$src")
    #       echo "copying $src" >&2
    #       ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
    #     done
    #   '';
  };

  nix = {
    enable = false;
    extraOptions = ''
      auto-optimise-store = true
      experimental-features = nix-command flakes
      extra-platforms = x86_64-darwin aarch64-darwin
    '';
  };

  users.users.${user} = {
    home = "/Users/${user}";
  };

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };

    casks = [
      # "discord"
      # "visual-studio-code"
    ];
  };
}
