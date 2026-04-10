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
    #
    #   # NOTE: with sops module enabled, provide secret files:
    #   # ~/.config/sops-nix/secrets/openclawGatewayToken
    #   # ~/.config/sops-nix/secrets/openclawTelegramBotToken
    #   # ~/.config/sops-nix/secrets/gemini
    #
    #   # NOTE: this mirrors current live setup defaults:
    #   # - model: openai-codex/gpt-5.4
    #   # - telegram allowFrom/groupAllowFrom: 3942079, 13252999
    #   # - secondary restricted wife agent + direct telegram binding for 13252999
    #   # - nix-openclaw-managed launchd/systemd + config lifecycle
    # };
    # codex = enabled;
    # claude-code = enabled;
    user = {
      enable = true;
      packages = with pkgs; [
        podman
        brave
        bitwarden-desktop
        openai-whisper
        antigravity
        gemini-cli
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
