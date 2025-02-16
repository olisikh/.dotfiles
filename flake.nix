{
  description = "Oleksii's Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    darwin-util.url = "github:hraban/mac-app-util";
    darwin-util.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    # NOTE: since lldb is broken in nixpkgs on main, this fix is very handy
    vscodelldb-fix.url = "github:mstone/nixpkgs/darwin-fix-vscode-lldb";
  };

  outputs = { nixpkgs, ... } @ inputs:
    let
      system = "aarch64-darwin";

      pkgs = import nixpkgs {
        inherit system;

        config = {
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
                vscode-lldb = inputs.vscodelldb-fix.legacyPackages."${system}".vscode-extensions.vadimcn.vscode-lldb;
              };
            };
          })

          inputs.neovim-nightly-overlay.overlays.default
        ];
      };
    in
    {
      darwinConfigurations =
        let inherit (inputs.darwin.lib) darwinSystem; in
        {
          olisikh =
            let
              username = "olisikh";
              specialArgs = { inherit inputs username; };
            in
            darwinSystem {
              inherit system pkgs specialArgs;

              modules = [
                ./nix/darwin.nix
                inputs.home-manager.darwinModules.home-manager
                inputs.darwin-util.darwinModules.default
                {
                  home-manager = {
                    extraSpecialArgs = specialArgs;

                    useGlobalPkgs = true;
                    useUserPackages = true;

                    users."${username}".imports = [
                      inputs.nixvim.homeManagerModules.nixvim
                      inputs.darwin-util.homeManagerModules.default
                      ./nix/home.nix
                    ];
                  };
                }
              ];
            };

          work =
            let
              username = "O.Lisikh";
              specialArgs = { inherit inputs username; };
            in
            darwinSystem {
              inherit system pkgs specialArgs;

              modules = [
                ./nix/darwin.nix
                inputs.home-manager.darwinModules.home-manager
                inputs.darwin-util.darwinModules.default
                {
                  home-manager = {
                    extraSpecialArgs = specialArgs;

                    useGlobalPkgs = true;
                    useUserPackages = true;

                    users."${username}".imports = [
                      inputs.nixvim.homeManagerModules.nixvim
                      inputs.darwin-util.homeManagerModules.default
                      ./nix/work.nix
                    ];
                  };
                }
              ];
            };
        };
    };
}
