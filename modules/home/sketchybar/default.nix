{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.sketchybar;
in
{
  options.${namespace}.sketchybar = {
    enable = mkBoolOpt false "Enable sketchybar program";
  };

  config = mkIf cfg.enable {
    home.file = {
      # NOTE: taken from here: https://github.com/MiragianCycle/dotfiles/tree/main/sketchybar
      # Reddit post: https://www.reddit.com/r/unixporn/comments/1d8pc0g/comment/l7b8r0l/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
      ".config/sketchybar".source = ./config;
    };
  };
}
