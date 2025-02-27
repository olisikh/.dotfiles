{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.colima;
  username = config.${namespace}.user.name;
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

      systemPath = [ "${pkgs.colima}/bin" "${pkgs.docker}/bin" ];
    };

    launchd.agents = {
      "colima.default" = {
        command = "${pkgs.colima}/bin/colima start --foreground";
        serviceConfig = {
          Label = "com.colima.default";
          RunAtLoad = true;
          KeepAlive = true;

          # not sure where to put these paths and not reference a hard-coded `$HOME`; `/var/log`?
          StandardOutPath = "/var/log/colima/default/daemon/launchd.stdout.log";
          StandardErrorPath = "/var/log/colima/default/daemon/launchd.stderr.log";

          # not using launchd.agents.<name>.path because colima needs the system ones as well
          EnvironmentVariables = {
            PATH = "${pkgs.colima}/bin:${pkgs.docker}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
            TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
            DOCKER_HOST = "unix:///Users/${username}/.colima/default/docker.sock";
          };
        };
      };
    };
  };
}
