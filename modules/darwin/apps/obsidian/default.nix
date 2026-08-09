{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.apps.obsidian;
  homebrewCfg = config.${namespace}.core.homebrew;
  userCfg = config.${namespace}.core.user;
  vaultName = baseNameOf cfg.backend.vaultPath;

  obsidianLauncher = pkgs.writeShellScript "obsidian-backend" ''
    set -eu
    /usr/bin/open -g "obsidian://open?vault=${vaultName}"
    while /usr/bin/pgrep -x Obsidian >/dev/null 2>&1; do
      /bin/sleep 30
    done
    exit 1
  '';
in
{
  options.${namespace}.apps.obsidian = {
    enable = mkBoolOpt false "Enable Obsidian";

    backend = {
      enable = mkBoolOpt false "Keep Obsidian running as the local notes backend";

      vaultPath = mkOpt types.str "${userCfg.home}/notes" "Vault opened by the Obsidian backend";
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "Obsidian requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "obsidian" ];

    launchd.user.agents.obsidian = mkIf cfg.backend.enable {
      path = [ config.environment.systemPath ];

      serviceConfig = {
        Label = "com.olisikh.obsidian";
        ProgramArguments = [ "${obsidianLauncher}" ];
        WorkingDirectory = userCfg.home;
        EnvironmentVariables = {
          HOME = userCfg.home;
        };
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 10;
        StandardOutPath = "${userCfg.home}/Library/Logs/Obsidian-backend.stdout.log";
        StandardErrorPath = "${userCfg.home}/Library/Logs/Obsidian-backend.stderr.log";
      };
    };
  };
}
