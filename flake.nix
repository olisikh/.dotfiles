{
  description = "Oleksii's Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NOTE: since lldb is broken in nixpkgs on main, this fix is very handy
    lldb-nix-fix.url = "github:mstone/nixpkgs/darwin-fix-vscode-lldb";
  };

  outputs = { nixpkgs, flake-utils, home-manager, nixvim, lldb-nix-fix, ... } @ inputs:
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

              # NOTE: override lldb package
              vscode-extensions = prev.vscode-extensions // {
                vadimcn = prev.vscode-extensions.vadimcn // {
                  vscode-lldb = lldb-nix-fix.legacyPackages.${system}.vscode-extensions.vadimcn.vscode-lldb;
                };
              };
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

        packages.homeConfigurations = {
          # personal
          home = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              nixvim.homeManagerModules.nixvim
              ./nix/home.nix
            ];
          };

          # work
          work = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              nixvim.homeManagerModules.nixvim
              ./nix/work.nix
            ];
          };
        };
      }
    );
}
