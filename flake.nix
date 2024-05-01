{
  description = "Darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, flake-utils, home-manager, ... } @ inputs:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
        "x86_64-darwin"
      ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        overlays = [
          inputs.neovim-nightly-overlay.overlay
        ];
      in
      {
        formatter = pkgs.alejandra;

        # personal
        packages.homeConfigurations.home = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;

            overlays = overlays;

            config = {
              # all installing packages considered not free by Nix community (e.g. Terraform)
              allowUnfree = true;
              allowUnfreePredicate = _: true;

              # allows package installation even if it claims system is not supported (sometimes it's a lie)
              # allowUnsupportedSystem = true;
            };
          };
          modules = [
            ./nix/home.nix
          ];
        };


        # work
        packages.homeConfigurations.work = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;

            overlays = overlays;

            config = {
              # all installing packages considered not free by Nix community (e.g. Terraform)
              allowUnfree = true;
              allowUnfreePredicate = _: true;
            };
          };
          modules = [
            ./nix/work.nix
          ];
        };

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
        };
      }
    );
}
