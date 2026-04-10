{ lib, namespace, config, pkgs, ... }:
let
  inherit (lib.${namespace}) enabled disabled;

  userCfg = config.${namespace}.user;
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
    user = {
      enable = true;
      packages = with pkgs; [ slack ];
    };
    sops = {
      enable = true;
      secrets = {
        userEmail = {
          path = "git/userEmail";
        };
        signingKey = {
          path = "git/signingKey";
        };
        opencode = {
          path = "ai/opencode/apiKey";
        };
        openai = {
          path = "ai/openai/apiKey";
        };
        openrouter = {
          path = "ai/openrouter/apiKey";
        };
        gemini = {
          path = "ai/gemini/apiKey";
        };
      };
      sshKeyPaths = [
        "${userCfg.home}/.ssh/id_rsa"
      ];
    };
  };
}
