{ config, pkgs, ... }:
let
  user = "O.Lisikh";
  homeDir = "/Users/${user}";
in
{
  home = {
    import = ./packages.nix;

    username = user;
    homeDirectory = homeDir;
    stateVersion = "22.11";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
