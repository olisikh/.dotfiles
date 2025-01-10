{ pkgs, ... }:
let
  user = "olisikh";

  ipkgs = import <nixpkgs> { system = "x86_64-darwin"; };
  bloop = ipkgs.bloop;
  jdk = pkgs.jdk17;
  scala = pkgs.scala-next;
in
{
  imports = [
    ./zsh
    ./fzf
    ./zoxide
    ./wezterm
    ./ripgrep
    ./starship
    ./git
    ./mc
    ./direnv
    ./nixvim
  ];

  home = {
    username = user;
    homeDirectory = "/Users/${user}";

    # don't ever change the stateVersion value, it will break the state
    stateVersion = "22.11";

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
      nix-prefetch
      bash
      wget
      nerd-fonts.meslo-lg
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      fd
      eza
      jq
      zoxide
      rustup
      tree-sitter
      luarocks-nix
      docker
      minikube
      kubernetes-helm
      terraform
      nodejs
      (yarn.override { nodejs = nodejs; })
      go
      jdk
      kafkactl
      awscli2
      kcat
      bun
      stern # kubectl pod log scraping tool
      htop
      pngpaste
      nodejs
      scala-next # latest Scala (currently Scala 3 with bundled in Scala CLI)
      (bloop.override { jre = jdk; })
      (sbt.override { jre = jdk; })
      (metals.override { jre = jdk; })
      kotlin
      gradle
      xdg-utils # open apps from console/neovim
      arc-browser
      wezterm
      lazygit
      gh
      watch
      (python3.withPackages (ps: with ps; [
        pip
        pytest
        debugpy
      ]))
      ollama
      obsidian
      vscode

      (writeShellScriptBin "home" (import ./script.nix { homeManagerConfig = "home"; }))
    ];

    sessionVariables = {
      SCALA_HOME = scala;
      SCALA_CLI_POWER = "true";
      JAVA_HOME = jdk;
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
  };
}
