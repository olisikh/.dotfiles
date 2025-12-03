{
  description = "Oleksii's system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";

    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-flake = {
      url = "github:snowfallorg/flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        snowfall-lib.follows = "snowfall-lib";
      };
    };

    # NOTE: since lldb is broken in nixpkgs on main, this fix is very handy
    vscodelldb-fix.url = "github:mstone/nixpkgs/darwin-fix-vscode-lldb";
  };

  outputs = inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;

        src = ./.;

        snowfall = {
          namespace = "olisikh";
          meta = {
            name = "olisikh";
            title = "Oleksii's snowfall flake";
          };
        };
      };
    in
    lib.mkFlake {
      inherit inputs;

      src = ./.;

      # NOTE: add external overlays here
      overlays = [];

      channels-config.allowUnfree = true;

      systems.modules.darwin = with inputs; [
        sops-nix.darwinModules.sops
      ];

      homes.modules = with inputs; [
        sops-nix.homeManagerModules.sops
        nixvim.homeModules.nixvim
      ];
    };
}
