{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.repobar;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.apps.repobar = {
    enable = mkBoolOpt false "Enable RepoBar (menu bar dashboard for GitHub repository health)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "RepoBar requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "repobar" ];
  };
}
