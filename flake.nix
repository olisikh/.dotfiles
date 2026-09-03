{
  description = "Oleksii's system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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

    nix-jetbrains-plugins = {
      url = "github:nix-community/nix-jetbrains-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      # Supplies the upstream Home Manager service module; the Hermes package
      # itself comes from the shared llm-agents.nix input.
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      # https://github.com/numtide/llm-agents.nix - AI coding agents & dev tools
      # Keep llm-agents' own nixpkgs pin: Hermes' Python dependency set is
      # tested against it and is not compatible with every consumer nixpkgs.
      url = "github:numtide/llm-agents.nix";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    obsidian-extensions = {
      url = "github:karaolidis/nix-obsidian-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    direnv-instant = {
      url = "github:Mic92/direnv-instant";
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
      overlays = with inputs; [
        llm-agents.overlays.shared-nixpkgs
        obsidian-extensions.overlays.default
      ];

      channels-config.allowUnfree = true;

      systems.modules.darwin = with inputs; [
        sops-nix.darwinModules.sops
      ];

      homes.modules = with inputs; [
        sops-nix.homeManagerModules.sops
        nixvim.homeModules.nixvim
        direnv-instant.homeModules.direnv-instant
        hermes-agent.homeManagerModules.default
      ];

      alias.templates.default = "empty";

      templates = {
        empty.description = "A Nix snowfall-lib flake";
        shell.description = "A Nix flake with a shell.nix.";
        darwin.description = "A Nix template with a dawrin module.";
        home.description = "A Nix template with a home-manager module.";
      };
    };
}
