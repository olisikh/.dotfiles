{ pkgs, lib, namespace, config, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.yazi;
in
{
  options.${namespace}.yazi = {
    enable = mkBoolOpt false "Enable yazi file manager";
  };

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      settings = { };
      plugins = with pkgs.yaziPlugins; {
        inherit git sudo chmod lazygit starship;
      };
    };
  };
}
        
