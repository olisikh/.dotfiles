{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf mkMerge mkOption types;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.network.tailscale;
  userCfg = config.${namespace}.core.user;
  caddyCfg = cfg.caddy;
  golinkCfg = cfg.golink;

  caddyConfig = pkgs.writeText "tailscale-caddyfile" ''
    {
      admin off
      auto_https off
    }

    # Tailscale Serve is the only remote-facing layer. Keep Caddy strictly
    # loopback-only and rewrite the Host header required by Hermes' guard.
    :${toString caddyCfg.port} {
      bind 127.0.0.1

      reverse_proxy ${caddyCfg.upstream} {
        header_up Host "${caddyCfg.upstream}"
        header_up X-Forwarded-Proto "https"
      }
    }
  '';

  caddyWrapper = pkgs.writeShellScript "tailscale-caddy-start" ''
    set -euo pipefail
    mkdir -p ${lib.escapeShellArg caddyCfg.logsDir}
    exec ${caddyCfg.package}/bin/caddy run \
      --config ${caddyConfig} \
      --adapter caddyfile
  '';

  golinkWrapper = pkgs.writeShellScript "golink-start" ''
    set -euo pipefail

    data_dir=${lib.escapeShellArg golinkCfg.dataDir}
    config_dir=${lib.escapeShellArg golinkCfg.configDir}
    auth_key_file=${lib.escapeShellArg golinkCfg.authKeyFile}

    umask 077
    mkdir -p "$data_dir" "$config_dir" "$data_dir/logs"

    if [[ ! -r "$auth_key_file" ]]; then
      echo "golink auth key is unavailable at $auth_key_file" >&2
      exit 78
    fi

    export TS_AUTHKEY="$(tr -d '\r\n' < "$auth_key_file")"
    exec ${golinkCfg.package}/bin/golink \
      -hostname ${lib.escapeShellArg golinkCfg.hostname} \
      -config-dir "$config_dir" \
      -sqlitedb ${lib.escapeShellArg golinkCfg.databasePath}
  '';
in
{
  options.${namespace}.network.tailscale = {
    enable = mkBoolOpt false "Enable Tailscale";

    caddy = {
      enable = mkBoolOpt false "Enable the loopback-only Caddy bridge for Tailscale Serve";

      package = mkOption {
        type = types.package;
        default = pkgs.caddy;
        description = "Caddy package to run.";
      };

      port = mkOption {
        type = types.port;
        default = 9120;
        description = "Loopback port on which Caddy accepts Tailscale Serve traffic.";
      };

      upstream = mkOption {
        type = types.str;
        default = "127.0.0.1:9119";
        description = "Loopback upstream to proxy while rewriting the Host header.";
      };

      logsDir = mkOption {
        type = types.str;
        default = "${userCfg.home}/Library/Logs/Tailscale";
        description = "Directory for Caddy bridge logs.";
      };
    };

    golink = {
      enable = mkBoolOpt false "Enable the private Golink service";

      package = mkOption {
        type = types.package;
        default = pkgs.golink;
        description = "Golink package to run.";
      };

      hostname = mkOption {
        type = types.str;
        default = "go";
        description = "Tailscale hostname for the Golink node.";
      };

      dataDir = mkOption {
        type = types.str;
        default = "${userCfg.home}/Library/Application Support/Golink";
        description = "Directory for Golink's SQLite database, tsnet state, and logs.";
      };

      configDir = mkOption {
        type = types.str;
        default = "${golinkCfg.dataDir}/tsnet";
        description = "Directory for Golink's embedded Tailscale state.";
      };

      databasePath = mkOption {
        type = types.str;
        default = "${golinkCfg.dataDir}/golink.db";
        description = "Path to Golink's SQLite database.";
      };

      authKeyFile = mkOption {
        type = types.str;
        default = "${userCfg.home}/.config/sops-nix/secrets/tailscale/golink-auth-key";
        description = "Runtime path to the SOPS-materialized Tailscale auth key.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.tailscale.enable = true;
    }

    (mkIf caddyCfg.enable {
      environment.systemPackages = [ caddyCfg.package ];

      launchd.user.agents.tailscale-caddy = {
        path = [ config.environment.systemPath ];

        serviceConfig = {
          Label = "com.tailscale.caddy";
          KeepAlive = true;
          RunAtLoad = true;
          ThrottleInterval = 10;
          WorkingDirectory = userCfg.home;
          ProgramArguments = [ "${caddyWrapper}" ];
          StandardOutPath = "${caddyCfg.logsDir}/caddy.stdout.log";
          StandardErrorPath = "${caddyCfg.logsDir}/caddy.stderr.log";
        };
      };
    })

    (mkIf golinkCfg.enable {
      environment.systemPackages = [ golinkCfg.package ];

      launchd.user.agents.golink = {
        path = [ config.environment.systemPath ];

        serviceConfig = {
          Label = "com.tailscale.golink";
          KeepAlive = true;
          RunAtLoad = true;
          ThrottleInterval = 10;
          WorkingDirectory = golinkCfg.dataDir;
          ProgramArguments = [ "${golinkWrapper}" ];
          StandardOutPath = "${golinkCfg.dataDir}/logs/golink.stdout.log";
          StandardErrorPath = "${golinkCfg.dataDir}/logs/golink.stderr.log";
        };
      };
    })
  ]);
}
