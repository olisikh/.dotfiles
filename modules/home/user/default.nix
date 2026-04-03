{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;

  cfg = config.${namespace}.user;

  defaultUsername = config.snowfallorg.user.name or "O.Lisikh";
  defaultHomeDir =
    if pkgs.stdenv.isDarwin then
      "/Users/${cfg.username}"
    else
      "/home/${cfg.username}";

  jdk = pkgs.jdk21;
  scala = pkgs.scala-next;
in
{
  options.${namespace}.user = with types; {
    enable = mkBoolOpt false "Enable user programs";
    username = mkOpt str defaultUsername "Name of the user";
    home = mkOpt types.str defaultHomeDir "The user's home directory";

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Home manager packages to enable";
    };
  };

  config = mkIf cfg.enable {
    home = {
      username = cfg.username;
      homeDirectory = cfg.home;

      # don't ever change the stateversion value, it will break the state
      stateVersion = "25.05";

      packages = with pkgs; [
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
        minikube
        k9s
        kubectl
        kubernetes-helm
        kustomize
        etcd
        terraform

        nodejs
        (pnpm.override { inherit nodejs; })
        (yarn.override { inherit nodejs; })
        bun

        jdk
        kafkactl
        awscli2
        # kcat
        stern # kubectl pod log scraping tool

        htop
        pngpaste

        scala
        (sbt.override { jre = jdk; })
        (metals.override { jre = jdk; })
        (bloop.override { jre = jdk; })

        kotlin
        gradle

        xdg-utils # open apps from console/neovim
        wezterm


        docker
        docker-compose
        docker-buildx

        lazygit
        lazydocker
        gh
        github-copilot-cli
        watch
        (python3.withPackages (ps: with ps; [
          pytest
          debugpy
        ]))
        mkalias
        pre-commit

        age
        gnupg # tool for generating gpg keys
        sops

        tflint
        esbuild

        bchunk
        dos2unix

        (writeShellScriptBin "home" (import ./script.nix {
          inherit config namespace lib;
          home = cfg.home;
        }))
      ] ++ cfg.packages;

      sessionVariables = {
        SCALA_HOME = scala;
        SCALA_CLI_POWER = "true";
        JAVA_HOME = jdk;
      };
    };

    # Ensure HM GUI apps are linked to ~/Applications on macOS.
    targets.darwin.linkApps = {
      enable = true;
      directory = "Applications/Home Manager Apps";
    };

    home.activation.linkDarwinApplications = lib.mkAfter ''
      # Keep HM apps visible to Spotlight/Raycast launchers by creating Finder aliases in ~/Applications
      # and re-registering them with LaunchServices.
      src_dir="$HOME/Applications/Home Manager Apps"
      dst_dir="$HOME/Applications"
      lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

      mkdir -p "$dst_dir"
      if [ -d "$src_dir" ]; then
        for app in "$src_dir"/*.app; do
          [ -e "$app" ] || continue

          app_name="$(basename "$app")"
          dst="$dst_dir/$app_name"

          # Avoid deleting a real app bundle placed manually in ~/Applications.
          if [ -d "$dst" ] && [ ! -L "$dst" ]; then
            continue
          fi

          if [ -L "$dst" ] || [ -f "$dst" ]; then
            rm -f "$dst"
          fi

          source_app="$app"
          if [ -L "$app" ]; then
            source_app="$(readlink "$app")"
          fi

          ${pkgs.mkalias}/bin/mkalias "$source_app" "$dst"
          "$lsregister" -f "$dst" >/dev/null 2>&1 || true
        done
      fi
    '';

    # let home manager install and manage itself.
    programs.home-manager.enable = true;
  };
}
