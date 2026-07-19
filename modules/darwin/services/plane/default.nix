{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf mkOption types;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.plane;
  userCfg = config.${namespace}.core.user;
  python = pkgs.python312;
  composeFile = ./compose/docker-compose.yaml;
  composeOverride = ./compose/compose.override.yaml;
  dispatcherDir = ./dispatcher;
  scriptsDir = ./scripts;

  commonEnvironment = {
    PLANE_STATE_DIR = cfg.stateDir;
    PLANE_SECRETS_DIR = cfg.secretsDir;
    PLANE_PUBLIC_BASE = cfg.publicBase;
    PLANE_TAILNET_HOST = cfg.tailnetHost;
    PLANE_PROXY_PORT = toString cfg.proxyPort;
  };

  patchPlaneWebIndex = pkgs.writers.writePython3 "patch-plane-web-index" {
    libraries = [];
    doCheck = false;
  } ''
    from __future__ import annotations

    import os
    import subprocess
    import sys
    from pathlib import Path

    def run(*args, check=True, timeout=60):
        result = subprocess.run(
            list(args),
            capture_output=True,
            text=True,
            check=check,
            timeout=timeout,
        )
        return result.stdout

    def main():
        state_dir = Path(os.environ.get("PLANE_STATE_DIR", ""))
        if not state_dir:
            raise SystemExit("PLANE_STATE_DIR is required")
        state_dir.mkdir(mode=0o700, parents=True, exist_ok=True)

        output = state_dir / "plane-web-index.html"
        container = os.environ.get("PLANE_WEB_CONTAINER", "plane-web-1")
        src_path = os.environ.get("PLANE_WEB_SRC_PATH", "/usr/share/nginx/html/index.html")

        polyfill = (
            "<script>"
            "window.requestIdleCallback=window.requestIdleCallback||"
            "function(cb,opts){var start=performance.now(),timeout=(opts&&opts.timeout)||50;"
            "return setTimeout(function(){"
            "cb({didTimeout:false,timeRemaining:function(){return Math.max(0,timeout-(performance.now()-start));}});"
            "},1);};"
            "window.cancelIdleCallback=window.cancelIdleCallback||function(id){clearTimeout(id);};"
            "</script>"
        )

        try:
            image = run("docker", "inspect", "-f", "{{.Config.Image}}", container).strip()
            if not image:
                raise SystemExit(f"could not determine image for {container}")
        except subprocess.CalledProcessError as exc:
            raise SystemExit(f"could not inspect {container}: {exc.stderr}") from exc
        except FileNotFoundError as exc:
            raise SystemExit("docker CLI is not available") from exc

        try:
            html = run("docker", "run", "--rm", "--entrypoint", "cat", image, src_path)
        except subprocess.CalledProcessError as exc:
            raise SystemExit(f"could not extract {src_path} from {image}: {exc.stderr}") from exc

        marker = "</head>"
        if marker not in html:
            raise SystemExit(f"{src_path} has no </head> tag; cannot inject polyfill")

        patched = html.replace(marker, polyfill + marker, 1)

        temporary = output.with_suffix(".tmp")
        temporary.write_text(patched, encoding="utf-8")
        temporary.chmod(0o600)
        temporary.replace(output)
        print(f"patched {output} from {image} ({len(patched)} bytes)", file=sys.stderr)

    if __name__ == "__main__":
        main()
  '';

  mkMcpRunner = name: pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = [ python cfg.mcpPackage ];
    text = ''
      set -euo pipefail
      umask 077
      mkdir -p "$PLANE_STATE_DIR/logs"
      chmod 700 "$PLANE_STATE_DIR" "$PLANE_STATE_DIR/logs"

      agent_env="$PLANE_STATE_DIR/plane-agent.env"
      if [[ ! -r "$agent_env" && -r "${cfg.legacyRuntimeDir}/plane-agent.env" ]]; then
        agent_env="${cfg.legacyRuntimeDir}/plane-agent.env"
      fi
      if [[ ! -r "$agent_env" ]]; then
        echo "Plane MCP needs plane-agent.env in $PLANE_STATE_DIR or ${cfg.legacyRuntimeDir}" >&2
        exit 78
      fi

      api_key_file="${cfg.secretsDir}/hermes-api-token"
      if [[ ! -s "$api_key_file" ]]; then
        echo "Plane MCP needs a materialized Plane API token at $api_key_file" >&2
        exit 78
      fi
      PLANE_API_KEY="$(tr -d '\r\n' < "$api_key_file")"
      export PLANE_API_KEY

      # shellcheck disable=SC1090
      source "$agent_env"
      while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^# ]] && continue
        export "$key=$value"
      done < "$agent_env"
      : "''${PLANE_WORKSPACE_SLUG:?PLANE_WORKSPACE_SLUG is required}"
      export PLANE_INTERNAL_BASE_URL="http://127.0.0.1:${toString cfg.proxyPort}"
      export PLANE_MCP_PORT="''${PLANE_MCP_PORT:-8211}"
      exec ${cfg.mcpPackage}/bin/plane-mcp-server
    '';
  };

  mcpRunner = mkMcpRunner "plane-mcp-runner";
  canaryMcpRunner = mkMcpRunner "plane-mcp-canary-runner";

  supervisor = pkgs.writeShellApplication {
    name = "plane-supervisor";
    runtimeInputs = [ pkgs.docker python patchPlaneWebIndex ];
    text = ''
      set -euo pipefail
      umask 077
      mkdir -p "$PLANE_STATE_DIR/logs"
      chmod 700 "$PLANE_STATE_DIR" "$PLANE_STATE_DIR/logs"
      ${python}/bin/python ${scriptsDir}/render-plane-env.py

      until ${pkgs.docker}/bin/docker info >/dev/null 2>&1; do
        sleep 2
      done

      compose() {
        ${pkgs.docker}/bin/docker compose \
          --project-name ${cfg.composeProject} \
          --env-file "$PLANE_STATE_DIR/plane.env" \
          --file ${composeFile} \
          --file ${composeOverride} \
          "$@"
      }

      compose up -d --no-build

      # Patch the Plane web index.html with a Safari-compatible
      # requestIdleCallback polyfill. WebKit on iOS does not implement
      # requestIdleCallback, which crashes Plane's board/gantt layout loader.
      # We extract the live index.html from the running container, inject the
      # polyfill, and bind-mount it back. This is idempotent and adapts to
      # future Plane frontend image updates.
      ${patchPlaneWebIndex}

      for _ in $(seq 1 60); do
        if ${scriptsDir}/plane-healthcheck; then
          break
        fi
        sleep 2
      done
      ${scriptsDir}/plane-healthcheck || { echo "Plane proxy did not become healthy" >&2; exit 1; }
      while sleep 10; do
        if [[ -z "$(compose ps --status running --quiet proxy)" ]]; then
          compose up -d --no-build
        fi
      done
    '';
  };

  dispatcher = pkgs.writeShellApplication {
    name = "plane-dispatcher";
    runtimeInputs = [ python ];
    text = ''
      set -euo pipefail
      umask 077
      mkdir -p "$PLANE_STATE_DIR/logs"
      chmod 700 "$PLANE_STATE_DIR" "$PLANE_STATE_DIR/logs"
      exec ${python}/bin/python ${dispatcherDir}/run.py
    '';
  };

  productionServiceConfig = label: program: {
    Label = label;
    KeepAlive = cfg.productionActive;
    RunAtLoad = cfg.productionActive;
    ThrottleInterval = 10;
    WorkingDirectory = cfg.stateDir;
    ProgramArguments = [ program ];
    EnvironmentVariables = commonEnvironment;
    StandardOutPath = "${cfg.stateDir}/logs/${label}.stdout.log";
    StandardErrorPath = "${cfg.stateDir}/logs/${label}.stderr.log";
  };
in
{
  options.${namespace}.services.plane = {
    enable = mkBoolOpt false "Install Nix-managed Plane service definitions.";

    productionActive = mkBoolOpt false "Allow the Nix production agents to start automatically.";

    mcpPackage = mkOption {
      type = types.package;
      default = pkgs.${namespace}.plane-mcp;
      description = "Pinned Plane MCP package used by the local HTTP runners.";
    };

    stateDir = mkOption {
      type = types.str;
      default = "${userCfg.home}/Library/Application Support/Plane";
      description = "User-owned Plane runtime state: generated env, queue, identity, and logs.";
    };

    legacyRuntimeDir = mkOption {
      type = types.str;
      default = "${userCfg.home}/services/plane/runtime";
      description = "Read-only fallback location for the existing Plane agent identity during migration.";
    };

    secretsDir = mkOption {
      type = types.str;
      default = "${userCfg.home}/.config/sops-nix/secrets/plane";
      description = "Directory of SOPS-materialized Plane secret files.";
    };

    composeProject = mkOption {
      type = types.str;
      default = "plane";
      description = "Docker Compose project name; keep this stable to retain existing volumes.";
    };

    proxyPort = mkOption {
      type = types.port;
      default = 28080;
      description = "Loopback HTTP port of the Plane proxy.";
    };

    dispatcherPort = mkOption {
      type = types.port;
      default = 9801;
      description = "Loopback port for signed Plane webhook ingress.";
    };

    mcpPort = mkOption {
      type = types.port;
      default = 8211;
      description = "Production loopback HTTP MCP port.";
    };

    tailnetHost = mkOption {
      type = types.str;
      default = "olisikh-mini.bandicoot-scala.ts.net";
      description = "Tailnet hostname Plane owns at its root path.";
    };

    publicBase = mkOption {
      type = types.str;
      default = "https://olisikh-mini.bandicoot-scala.ts.net";
      description = "Public origin emitted by Plane.";
    };

    canary = {
      enable = mkBoolOpt false "Run a separately ported Nix MCP canary.";
      port = mkOption {
        type = types.port;
        default = 8212;
        description = "Loopback port reserved for the MCP canary.";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.mcpPackage ];

    launchd.user.agents = {
      plane = {
        path = [ config.environment.systemPath ];
        serviceConfig = productionServiceConfig "com.olisikh.plane-nix" "${supervisor}/bin/plane-supervisor";
      };

      plane-dispatcher = {
        path = [ config.environment.systemPath ];
        serviceConfig = (productionServiceConfig "com.olisikh.plane-dispatcher-nix" "${dispatcher}/bin/plane-dispatcher") // {
          EnvironmentVariables = commonEnvironment // {
            PLANE_DISPATCHER_PORT = toString cfg.dispatcherPort;
          };
        };
      };

      plane-mcp = {
        path = [ config.environment.systemPath ];
        serviceConfig = (productionServiceConfig "com.olisikh.plane-mcp-nix" "${mcpRunner}/bin/plane-mcp-runner") // {
          EnvironmentVariables = commonEnvironment // {
            PLANE_MCP_PORT = toString cfg.mcpPort;
          };
        };
      };
    } // lib.optionalAttrs cfg.canary.enable {
      plane-mcp-canary = {
        path = [ config.environment.systemPath ];
        serviceConfig = {
          Label = "com.olisikh.plane-mcp-canary";
          KeepAlive = true;
          RunAtLoad = true;
          ThrottleInterval = 10;
          WorkingDirectory = cfg.stateDir;
          ProgramArguments = [ "${canaryMcpRunner}/bin/plane-mcp-canary-runner" ];
          EnvironmentVariables = commonEnvironment // {
            PLANE_MCP_PORT = toString cfg.canary.port;
          };
          StandardOutPath = "${cfg.stateDir}/logs/plane-mcp-canary.stdout.log";
          StandardErrorPath = "${cfg.stateDir}/logs/plane-mcp-canary.stderr.log";
        };
      };
    };
  };
}
