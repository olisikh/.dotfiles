{ ... }: {
  configuration = {

    nix.settings.experimental-features = "nix-command flakes";

    nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
    };

    system.stateVersion = 5;

    nixpkgs.hostPlatform = "aarch64-darwin";
  };
}
