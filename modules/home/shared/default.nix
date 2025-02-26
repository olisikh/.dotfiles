{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.shared;

  jdk = pkgs.jdk17;
  scala = pkgs.scala-next;
in
{
  options.${namespace}.shared = {
    enable = mkBoolOpt false "Enable shared programs";
  };

  config = mkIf cfg.enable {
    home = {
      # username = "olisikh";
      # homedirectory = "/users/${username}";

      # don't ever change the stateversion value, it will break the state
      stateversion = "25.05";

      # the home.packages option allows you to install nix packages into your
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
        lazydocker
        gh
        gnupg # tool for generating gpg keys
        watch
        (python3.withpackages (ps: with ps; [
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

        (writeshellscriptbin "home" (import ./script.nix { homemanagerconfig = "home"; }))
      ];

      sessionvariables = {
        scala_home = scala;
        scala_cli_power = "true";
        java_home = jdk;
      };
    };

    # let home manager install and manage itself.
    programs.home-manager.enable = true;
  };
}
