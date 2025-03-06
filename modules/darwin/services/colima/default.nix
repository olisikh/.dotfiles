{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.colima;
  user = config.${namespace}.user;

  colimaDir = "${user.home}/.config/colima/default";
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
        TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
        DOCKER_HOST = "unix://${user.home}/.config/colima/default/docker.sock";
      };

      systemPath = [
        "${pkgs.colima}/bin"
        "${pkgs.docker}/bin"
      ];
    };

    launchd = {
      # NOTE: daemons are system-scoped services
      daemons = { };

      # NOTE: agents are user-scoped services
      agents = {
        # TODO: can't run colima as an agent because it is not designed to be run as root
        #
        # "com.colima.default" = {
        #   command = "${pkgs.colima}/bin/colima start --foreground";
        #   serviceConfig = {
        #     Label = "com.colima.default";
        #     RunAtLoad = true;
        #     KeepAlive = true;
        #
        #     StandardOutPath = "${colimaDir}/colima.stdout.log";
        #     StandardErrorPath = "${colimaDir}/colima.stderr.log";
        #
        #     EnvironmentVariables = {
        #       DOCKER_HOST = "unix://${colimaDir}/docker.sock";
        #       PATH = "${pkgs.colima}/bin:${pkgs.docker}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        #     };
        #   };
        # };
      };
    };
  };
}
