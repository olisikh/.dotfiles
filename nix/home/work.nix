{ pkgs, username, ... }:
let
  jdk = pkgs.jdk17;
  scala = pkgs.scala-next;
in
{
  imports = [
    ./programs/zsh
    ./programs/fzf
    ./programs/zoxide
    ./programs/wezterm
    ./programs/ripgrep
    ./programs/starship
    ./programs/git
    ./programs/mc
    ./programs/direnv
    ./programs/nixvim
    ./programs/sketchybar
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
      nerd-fonts.jetbrains-mono
      fd
      eza
      jq
      zoxide
      rustup
      tree-sitter
      luarocks-nix
      qemu
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
      scala
      (sbt.override { jre = jdk; })
      (metals.override { jre = jdk; })
      xdg-utils # open apps from console/neovim
      wezterm
      lazygit
      lazydocker
      gh
      gnupg # tool for generating GPG keys
      watch
      rover
      (python3.withPackages (ps: with ps; [
        pip
        pytest
        debugpy
      ]))
      ollama
      cmatrix

      (pkgs.writeShellScriptBin "home" (import ./script.nix { homeManagerConfig = "work"; }))
    ];

    sessionVariables = {
      SCALA_HOME = scala;
      JAVA_HOME = jdk;
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
  };
}
