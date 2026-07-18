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
    # loopback-only. Each application owns an explicit public prefix so that
    # their root-relative SPA/API paths never collide.
    :${toString caddyCfg.port} {
      bind 127.0.0.1

      # Hermes Dashboard supports a forwarded prefix, but its host/origin
      # guard still requires the loopback authority upstream.
      @dashboard_bare path ${caddyCfg.dashboardPrefix}
      redir @dashboard_bare ${caddyCfg.dashboardPrefix}/ permanent
      handle_path ${caddyCfg.dashboardPrefix}/* {
        reverse_proxy ${caddyCfg.upstream} {
          header_up Host "${caddyCfg.upstream}"
          header_up Origin "http://${caddyCfg.upstream}"
          header_up X-Forwarded-Prefix "${caddyCfg.dashboardPrefix}"
          header_up X-Forwarded-Proto "https"
        }
      }

      ${lib.optionalString caddyCfg.webui.enable ''
      # Hermes WebUI resolves normal UI/API/SSE paths from document.baseURI.
      # Strip the public prefix because its Python server is root-routed.
      @webui_bare path ${caddyCfg.webui.prefix}
      redir @webui_bare ${caddyCfg.webui.prefix}/ permanent
      handle_path ${caddyCfg.webui.prefix}/* {
        reverse_proxy ${caddyCfg.webui.upstream} {
          header_up X-Forwarded-Proto "https"
        }
      }
      ''}

      ${lib.optionalString caddyCfg.plane.enable ''
      # Plane emits root-relative browser assets and does not accept a path in
      # CORS_ALLOWED_ORIGINS. Preserve this legacy path as a safe redirect;
      # Plane itself owns the Tailnet host root below.
      @plane_legacy path ${caddyCfg.plane.prefix} ${caddyCfg.plane.prefix}/*
      redir @plane_legacy / permanent

      # Plane must be able to send a signed work-item webhook to a narrow
      # dispatcher without exposing Hermes' privileged webhook server.
      @plane_dispatch_bare path ${caddyCfg.plane.dispatcherPrefix}
      redir @plane_dispatch_bare ${caddyCfg.plane.dispatcherPrefix}/ permanent
      handle_path ${caddyCfg.plane.dispatcherPrefix}/* {
        reverse_proxy ${caddyCfg.plane.dispatcherUpstream} {
          header_up Host "{http.request.host}"
          header_up X-Forwarded-Proto "https"
        }
      }
      ''}

      ${lib.optionalString caddyCfg.openclaw.enable ''
      # OpenClaw owns its configured basePath, so preserve the prefix upstream.
      # Its WebSocket endpoint is the exact base path (without a trailing slash),
      # which must be proxied rather than redirected because WebSocket clients do
      # not follow HTTP redirects during the handshake.
      @openclaw path ${caddyCfg.openclaw.prefix} ${caddyCfg.openclaw.prefix}/*
      handle @openclaw {
        reverse_proxy ${caddyCfg.openclaw.upstream} {
          header_up X-Forwarded-Proto "https"
        }
      }
      ''}

      ${lib.optionalString caddyCfg.plane.enable ''
      # This catch-all is intentionally after every explicit application route.
      # It makes the root-relative Plane shell, assets, API and live endpoints
      # resolve on the Tailnet hostname without exposing the Compose proxy.
      handle {
        reverse_proxy ${caddyCfg.plane.upstream} {
          header_up Host "{http.request.host}"
          header_up X-Forwarded-Proto "https"
        }
      }
      ''}

      # Do not let an unmatched path fall through to a privileged application.
      ${lib.optionalString (!caddyCfg.plane.enable) ''
      @root path /
      redir @root ${caddyCfg.rootRedirect} permanent
      respond "Not Found" 404
      ''}
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
        description = "Hermes Dashboard loopback upstream to proxy while rewriting the Host header.";
      };

      dashboardPrefix = mkOption {
        type = types.str;
        default = "/hermes";
        description = "Public path prefix for the Hermes Dashboard.";
      };

      rootRedirect = mkOption {
        type = types.str;
        default = "/hermes/";
        description = "Public path used when a browser requests the bare Tailnet HTTPS root.";
      };

      webui = {
        enable = mkBoolOpt false "Expose Hermes WebUI below the shared Tailnet HTTPS proxy";

        prefix = mkOption {
          type = types.str;
          default = "/hermes-webui";
          description = "Public path prefix for Hermes WebUI.";
        };

        upstream = mkOption {
          type = types.str;
          default = "127.0.0.1:8787";
          description = "Hermes WebUI loopback upstream.";
        };
      };

      plane = {
        enable = mkBoolOpt false "Expose the loopback-only Plane Compose proxy below the shared Tailnet HTTPS bridge";

        prefix = mkOption {
          type = types.str;
          default = "/plane";
          description = "Public path prefix for Plane; the Compose upstream remains root-routed.";
        };

        upstream = mkOption {
          type = types.str;
          default = "127.0.0.1:28080";
          description = "Plane Compose proxy loopback upstream.";
        };

        dispatcherPrefix = mkOption {
          type = types.str;
          default = "/plane-dispatch";
          description = "Public Tailnet-only path for signed Plane webhooks.";
        };

        dispatcherUpstream = mkOption {
          type = types.str;
          default = "127.0.0.1:9801";
          description = "Plane dispatcher loopback upstream.";
        };
      };

      openclaw = {
        enable = mkBoolOpt false "Expose OpenClaw Control UI below the shared Tailnet HTTPS proxy";

        prefix = mkOption {
          type = types.str;
          default = "/openclaw";
          description = "Public path prefix for OpenClaw Control UI.";
        };

        upstream = mkOption {
          type = types.str;
          default = "127.0.0.1:18789";
          description = "OpenClaw Control UI loopback upstream.";
        };
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
