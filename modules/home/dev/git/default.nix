{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.git;
in
{
  options.${namespace}.dev.git = {
    enable = mkBoolOpt false "Enable Git tools (lazygit, gh, pre-commit)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      lazygit
      gh
      pre-commit
    ];
  };
}
