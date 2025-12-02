{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.colima;
  userCfg = config.${namespace}.user;

  colimaDir = "${userCfg.home}/.colima";

  colimaPkg = pkgs.colima;
  dockerPkg = pkgs.docker;
in
{
  options.${namespace}.services.colima = {
    enable = mkBoolOpt false "Enable colima module";
  };

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        lima
        colima
        docker
        docker-compose
      ];

      variables = {
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
        KeepAlive = true;

        StandardOutPath = "${colimaDir}/colima.stdout.log";
        StandardErrorPath = "${colimaDir}/colima.stderr.log";

        EnvironmentVariables = {
          HOME = userCfg.home;
        };
      };
    };
  };
}
