{ lib, namespace, config, ... }:
let
  inherit (lib.${namespace}) enabled disabled;

  user = config.${namespace}.user;
in
{
  olisikh = {
    direnv = enabled;
    zsh = enabled;
    fzf = enabled;
    zoxide = enabled;
    wezterm = enabled;
    ripgrep = enabled;
    starship = enabled;
    git = enabled;
    mc = enabled;
    nixvim = enabled;
    user = enabled;
    sops = {
      enable = true;
      sshKeyPaths = [
        "${user.home}/.ssh/id_rsa"
      ];
    };
  };
}
