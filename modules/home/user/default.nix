{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;

  cfg = config.${namespace}.user;

  defaultUsername = config.snowfallorg.user.name or "O.Lisikh";
  defaultHomeDir =
    if pkgs.stdenv.isDarwin then
      "/Users/${cfg.name}"
    else
      "/home/${cfg.name}";

  jdk = pkgs.jdk17;
  scala = pkgs.scala-next;
in
{
  options.${namespace}.user = with types; {
    enable = mkBoolOpt false "Enable user programs";
    name = mkOpt str defaultUsername "Name of the user";
    fullName = mkOpt types.str "Oleksii Lisikh" "Full name of the user";
    home = mkOpt types.str defaultHomeDir "The user's home directory";
  };

  config = mkIf cfg.enable {
    home = {
      username = cfg.name;
      homeDirectory = cfg.home;

      # don't ever change the stateversion value, it will break the state
      stateVersion = "25.05";

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

        age
        sops

        discord

        (writeShellScriptBin "home" (import ./script.nix))
      ];

      sessionVariables = {
        SCALA_HOME = scala;
        SCALA_CLI_POWER = "true";
        JAVA_HOME = jdk;
      };
    };

    # let home manager install and manage itself.
    programs.home-manager.enable = true;
  };
}
