{ lib, namespace, pkgs, ... }:
let
  inherit (lib.${namespace}) enabled disabled;
in
{
  olisikh = {
    direnv = enabled;
    zsh = enabled;
    fzf = enabled;
    zoxide = enabled;
    bat = enabled;
    wezterm = enabled;
    ripgrep = enabled;
    starship = enabled;
    git = enabled;
    yazi = enabled;
    nixvim = enabled;
    intellij-idea = {
      enable = true;
      plugins = [
        "com.github.catppuccin.jetbrains"
        "com.github.catppuccin.jetbrains_icons"
        "org.intellij.scala"
        "org.jetbrains.kotlin"
        "org.intellij.plugins.hcl"
        "Docker"
        "IdeaVIM"
        "Lombook Plugin"
        "youngstead.relative-line-numbers"
      ];
    };
    opencode = enabled;
    # openclaw = {
    #   enable = true;
    #   # NOTE: with sops module enabled, provide secret files:
    #   # ~/.config/sops-nix/secrets/openclawGatewayToken
    #   # ~/.config/sops-nix/secrets/openclawTelegramBotToken
    #   # ~/.config/sops-nix/secrets/gemini
    #   # then run OpenClaw via: ~/.local/bin/openclaw-with-secrets
    # };
    # codex = enabled;
    # claude-code = enabled;
    user = {
      enable = true;
      packages = with pkgs; [
        podman
        brave
        bitwarden-desktop
        antigravity
        obsidian
        vscode
        cmatrix
        (pulumi.withPackages (ps: with ps; [
          pulumi-nodejs
        ]))
        dotnet-sdk_10
      ];
    };
    sops = enabled;
  };
}
