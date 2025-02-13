{ pkgs, username, ... }:
let
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
    ./amethyst
    ./sketchybar
  ];

  home = {
    inherit username;

    homeDirectory = "/Users/${username}";

    # don't ever change the stateVersion value, it will break the state
    stateVersion = "25.05";

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
      lua
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
      scala
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
      cmatrix
      mkalias

      discord

      jankyborders # visible borders
      sketchybar # nice status bar
      sketchybar-app-font # font for sketchybar
      skhd # app navigation hotkeys (alt+t - terminal, alt+b - browser, etc)
      raycast

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
