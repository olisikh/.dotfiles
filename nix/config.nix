{ user }: { ... }:
{
  services.nix-daemon.enable = true;

  users.users.${user} = {
    home = "/Users/${user}";
  };

  nix.extraOptions = ''
    auto-optimise-store = true
    experimental-features = nix-command flakes
    extra-platforms = x86_64-darwin aarch64-darwin
  '';

  homebrew = {
    enable = true;

    casks = [
      # "discord"
      # "visual-studio-code"
    ];
  };
}
