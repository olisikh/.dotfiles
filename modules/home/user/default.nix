{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf types optionals;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;

  cfg = config.${namespace}.user;

  defaultUsername = config.snowfallorg.user.name or "O.Lisikh";
  defaultHomeDir =
    if pkgs.stdenv.isDarwin then
      "/Users/${cfg.username}"
    else
      "/home/${cfg.username}";

  jdk = pkgs.jdk17;
  scala = pkgs.scala-next;
in
{
  options.${namespace}.user = with types; {
    enable = mkBoolOpt true "Enable user programs";
    username = mkOpt str defaultUsername "Name of the user";
    home = mkOpt types.str defaultHomeDir "The user's home directory";

    personal = {
      enable = mkBoolOpt false "Enable personal user programs";
    };

    work = {
      enable = mkBoolOpt false "Enable work user programs";
    };
  };

  config = mkIf cfg.enable {
    home = {
      username = cfg.username;
      homeDirectory = cfg.home;

      # don't ever change the stateversion value, it will break the state
      stateVersion = "25.05";

      packages = with pkgs;
        [
          nix-prefetch
          nix-search-cli
          bash
          wget
          nerd-fonts.jetbrains-mono
          fd
          eza
          jq
          yq
          stress
          zoxide
          bat
          pay-respects # thefuck alternative
          rustup
          tree-sitter
          luarocks-nix
          minikube
          k9s
          kubectl
          kubernetes-helm
          kustomize
          etcd
          terraform
          nodejs
          pnpm
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
          kotlin
          gradle
          xdg-utils # open apps from console/neovim
          wezterm
          lazygit
          lazydocker
          gh
          gnupg # tool for generating gpg keys
          watch
          (python3.withPackages (ps: with ps; [
            pytest
            debugpy
          ]))
          uv # python utility belt
          mkalias
          pre-commit

          age
          sops

          tflint
          esbuild

          bchunk
          dos2unix

          (writeShellScriptBin "home" (import ./script.nix {
            inherit config namespace lib;
            home = cfg.home;
          }))
        ] ++
        (optionals cfg.personal.enable [
          code-cursor
          brave
          bitwarden-desktop
          antigravity
          obsidian
          vscode
          cmatrix
          (pulumi.withPackages (ps: with ps; [
            pulumi-nodejs
          ]))
        ]);

      sessionVariables = mkIf cfg.personal.enable {
        SCALA_HOME = scala;
        SCALA_CLI_POWER = "true";
        JAVA_HOME = jdk;
      };
    };

    # let home manager install and manage itself.
    programs.home-manager.enable = true;
  };
}
