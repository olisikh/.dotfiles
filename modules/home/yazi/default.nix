{ pkgs, lib, namespace, config, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.yazi;


  # catppuccinThemes = pkgs.fetchFromGitHub {
  #   owner = "catppuccin";
  #   repo = "yazi"; # Bat uses sublime syntax for its themes
  #   rev = "1a8c939e47131f2c4bd07a2daea7773c29e2a774";
  #   sha256 = "sha256-6fWoCH90IGumAMc4buLRWL0N61op+AuMNN9CAR9/OdI=";
  # };
in
{
  options.${namespace}.yazi = {
    enable = mkBoolOpt false "Enable yazi file manager";
  };

  config = mkIf cfg.enable {
    # home.file = {
    #   ".config/yazi/flavors".source = catppuccinThemes;
    # };

    programs.yazi = {
      enable = true;
      settings = {
        yazi = { };
        # theme = {
        #   flavor = {
        #     dark = "mocha";
        #   };
        # };
        keymap = { };
      };
      plugins = with pkgs.yaziPlugins; {
        inherit git sudo chmod lazygit starship;
      };
    };
  };
}
        
