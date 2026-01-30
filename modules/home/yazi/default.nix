{ pkgs, lib, namespace, config, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.yazi;

  themes = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "yazi";
    rev = "fc69d6472d29b823c4980d23186c9c120a0ad32c";
    sha256 = "sha256-Og33IGS9pTim6LEH33CO102wpGnPomiperFbqfgrJjw=";
  };
in
{
  options.${namespace}.yazi = {
    enable = mkBoolOpt false "Enable yazi file manager";
  };

  config = mkIf cfg.enable {
    home.file = {
      ".config/yazi/theme.toml".source = "${themes}/themes/mocha/catppuccin-mocha-blue.toml";
    };

    programs.yazi = {
      enable = true;
      settings = { };
      plugins = with pkgs.yaziPlugins; {
        inherit git sudo chmod lazygit starship;
      };
    };
  };
}
        
