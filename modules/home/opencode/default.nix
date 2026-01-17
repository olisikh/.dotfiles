{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.opencode;
in
{
  options.${namespace}.opencode = {
    enable = mkBoolOpt false "Enable OpenCode program";
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;

      settings = {
        theme = "catppuccin";
        autoupdate = false;
        autoshare = false;
      };
    };

    home.file = {
      # NOTE: Since oh-my-opencode is under active development, it makes more sense to install it ad-hoc for flexibility.
      # ".config/opencode/oh-my-opencode.json".source = ./config/oh-my-opencode.json;
    };
  };
}
