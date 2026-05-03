{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.network.tailscale;
  tailscalePkg = config.services.tailscale.package;
  tailscaleUp = pkgs.writeShellScript "tailscale-up" ''
    set -eu

    for _ in $(seq 1 60); do
      if ${tailscalePkg}/bin/tailscale up; then
        exit 0
      fi

      sleep 2
    done

    ${tailscalePkg}/bin/tailscale up
  '';
in
{
  options.${namespace}.network.tailscale = {
    enable = mkBoolOpt false "Enable tailscale module";
  };

  config = mkIf cfg.enable {
    services.tailscale.enable = true;

    launchd.daemons.tailscale-up = {
      path = [ config.environment.systemPath ];

      serviceConfig = {
        Label = "com.tailscale.up";
        ProgramArguments = [ "${tailscaleUp}" ];

        RunAtLoad = true;
        StartInterval = 30;
        KeepAlive = {
          NetworkState = true;
          SuccessfulExit = false;
        };

        StandardOutPath = "/var/log/tailscale-up.log";
        StandardErrorPath = "/var/log/tailscale-up.log";
      };
    };
  };
}
