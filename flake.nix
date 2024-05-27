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
        pkgs = import nixpkgs {
          inherit system;

          config = {
            # all installing packages considered not free by Nix community (e.g. Terraform)
            allowUnfree = true;
            allowUnfreePredicate = _: true;
          };

          overlays = [
            # adds $METALS_OPTS to pass extra JVM args to metals 
            (final: prev: {
              metals = prev.metals.overrideAttrs (oldAttrs: {
                installPhase = ''
                  mkdir -p $out/bin
                  makeWrapper ${prev.jre}/bin/java $out/bin/metals \
                    --add-flags "${oldAttrs.extraJavaOpts} \$METALS_OPTS -cp $CLASSPATH scala.meta.metals.Main"
                '';
              });
            })

            inputs.neovim-nightly-overlay.overlays.default
          ];
        };
      in
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
        };

        # personal
        packages.homeConfigurations.home = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./nix/home.nix ];
        };

        # work
        packages.homeConfigurations.work = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./nix/work.nix ];
        };
      }
    );
}
