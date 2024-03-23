{ inputs, pkgs, config, ... }:
let
  user = builtins.getEnv "USER";
  catppuccinFlavour = "mocha";
in
{
  imports = [
    (import ./zsh (catppuccinFlavour))
    ./git
    ./ripgrep
    (import ./bat (catppuccinFlavour))
    ./direnv
    ./starship
    ./zoxide
    (import ./alacritty (catppuccinFlavour))
    ./nvim
    (import ./alacritty (catppuccinFlavour))
    (import ./tmux (catppuccinFlavour))
    ./mc
  ];

  home = {
    username = user;
    homeDirectory = "/Users/${user}";

    stateVersion = "22.11";

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs;
      [
        nix-prefetch
        bash
        wget
        (nerdfonts.override {
          fonts = [ "Meslo" "JetBrainsMono" "FiraCode" "Hack" ];
        })
        fd
        fzf
        eza # exa fork, as original package is not maintained
        jq
        lua
        rustup
        luarocks
        tree-sitter
        python3
        docker
        minikube
        kubernetes-helm
        terraform
        yarn
        go
        jdk17
        kafkactl
        # awscli2
        kcat
        bun
        stern # kubectl pod log scraping tool
        htop
        nodejs
        (sbt.override {
          jre = jdk17;
        })
        coursier
        scala

        (pkgs.writeShellScriptBin "home-make" ''
          home-manager switch --flake ~/.dotfiles#${user} --impure
        '')
        (pkgs.writeShellScriptBin "home-update" ''
          nix flake update ~/.dotfiles
        '')
        (pkgs.writeShellScriptBin "home-upgrade" ''
          home-update && home-make
        '')
      ];

    sessionVariables = {
      JAVA_HOME = pkgs.jdk17;
      CATPPUCCIN_FLAVOUR = catppuccinFlavour; # still used by nvim lua files
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager = {
    enable = true;
  };
}
