{ lib, namespace, config, ... }:
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
    nixvim = {
      enable = true;
      plugins = {
        # NOTE: Obsidian is disabled because it doesn't build and I don't use it at work anyway 
        obsidian = disabled;
        avante = {
          enable = true;
          provider = "ollama";
        };
      };
    };
    user = enabled;
    sops = {
      enable = true;
      sshKeyPaths = [
        "${userCfg.home}/.ssh/id_rsa"
      ];
    };
  };
}
