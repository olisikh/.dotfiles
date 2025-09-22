{ pkgs, lib, namespace, config, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.yazi;

  themes = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "yazi";
    rev = "043ffae14e7f7fcc136636d5f2c617b5bc2f5e31";
    sha256 = "sha256-zkL46h1+U9ThD4xXkv1uuddrlQviEQD3wNZFRgv7M8Y=";
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
        
