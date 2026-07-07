{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.containers.colima;
  userCfg = config.${namespace}.core.user;

  colimaDir = cfg.dir;

  colimaPkg = pkgs.colima;
  dockerPkg = pkgs.docker;
in
{
  options.${namespace}.containers.colima = {
    enable = mkBoolOpt false "Enable colima module";
    dir = mkOpt types.str "${userCfg.home}/.colima" "Directory used as COLIMA_HOME";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [ lima colima ];

      variables = {
        COLIMA_HOME = colimaDir;
        DOCKER_HOST = "unix://${colimaDir}/docker.sock";
        TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
      };

      systemPath = [
        "${colimaPkg}/bin"
        "${dockerPkg}/bin"
      ];
    };

    launchd.user.agents.colima = {
      path = [ config.environment.systemPath ];

      serviceConfig = {
        Label = "org.colima.default";
        ProgramArguments = [ "${colimaPkg}/bin/colima" "start" "--foreground" ];

        RunAtLoad = true;
        KeepAlive.SuccessfulExit = true;

        ExitTimeOut = 120;

        StandardOutPath = "${colimaDir}/colima.stdout.log";
        StandardErrorPath = "${colimaDir}/colima.stderr.log";

        EnvironmentVariables = {
          HOME = userCfg.home;
          COLIMA_HOME = colimaDir;
        };
      };
    };
  };
}
