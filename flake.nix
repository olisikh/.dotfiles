{
  description = "Oleksii's Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";

    nix-darwin.url = "github:lnl7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    # NOTE: since lldb is broken in nixpkgs on main, this fix is very handy
    lldb-nix-fix.url = "github:mstone/nixpkgs/darwin-fix-vscode-lldb";
  };

  outputs = { nixpkgs, lldb-nix-fix, ... } @ inputs:
    let
      system = "aarch64-darwin";

      nixpkgsConfig = {
        config.allowUnfree = true;
        config.allowUnfreePredicate = _: true;

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
                vscode-lldb = lldb-nix-fix.legacyPackages.aarch64-darwin.vscode-extensions.vadimcn.vscode-lldb;
              };
            };
          })

          inputs.neovim-nightly-overlay.overlays.default
        ];
      };
    in
    {
      darwinConfigurations =
        let inherit (inputs.nix-darwin.lib) darwinSystem; in
        {
          home = darwinSystem {
            inherit system;

            specialArgs = { inherit inputs; };

            modules = [
              (import ./nix/config.nix { user = "olisikh"; })
              inputs.home-manager.darwinModules.home-manager
              inputs.nixvim.homeManagerModules.nixvim
              {
                nixpkgs = nixpkgsConfig;

                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.olisikh = import ./nix/home.nix;
              }
            ];
          };

          work = darwinSystem {
            inherit system;

            specialArgs = { inherit inputs; };

            modules = [
              (import ./nix/config.nix { user = "O.Lisikh"; })
              inputs.home-manager.darwinModules.home-manager
              inputs.nixvim.homeManagerModules.nixvim
              {
                nixpkgs = nixpkgsConfig;

                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users."O.Lisikh" = import ./nix/work.nix;
              }
            ];
          };
        };
    };
}
