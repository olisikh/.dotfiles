{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf;

  # cfg = config.${namespace}.nixvim.plugins.opencode;
in
{
  # options.${namespace}.nixvim.plugins.opencode = {
  #   enable = lib.mkBoolOpt true "Enable OpenCode plugin";
  # };


  plugins = {
    opencode = {
      enable = true;

      settings = { };
    };
  };
}
