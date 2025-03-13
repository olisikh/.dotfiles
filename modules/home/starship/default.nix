{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.starship;
in
{
  options.${namespace}.starship = {
    enable = mkBoolOpt false "Enable starship program";
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;

      settings = {
        scala.symbol = " ";
        java.symbol = " ";
        nix_shell.symbol = " ";
        nodejs.symbol = " ";
        golang.symbol = " ";
        rust.symbol = " ";
        docker_context.symbol = " ";
        haskell.symbol = " ";
        elixir.symbol = " ";
        lua.symbol = " ";
        terraform.symbol = " ";
        aws.symbol = "  ";
        gradle.symbol = " ";
      };
    };
  };
}
