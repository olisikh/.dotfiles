{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf mkOption types;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.productivity.vikunja;
  userCfg = config.${namespace}.core.user;
  python = pkgs.python312;
  composeFile = ./compose/docker-compose.yaml;
  scriptsDir = ./scripts;

  commonEnvironment = {
    VIKUNJA_STATE_DIR = cfg.stateDir;
    VIKUNJA_SECRETS_DIR = cfg.secretsDir;
    VIKUNJA_COMPOSE_PROJECT = cfg.composeProject;
    VIKUNJA_ENV_FILE = "${cfg.stateDir}/vikunja.env";
    VIKUNJA_PORT = toString cfg.port;
    VIKUNJA_SERVICE_PUBLICURL = cfg.publicBase;
    VIKUNJA_IMAGE_TAG = cfg.vikunjaImageTag;
    POSTGRES_IMAGE_TAG = cfg.postgresImageTag;
  };

  renderer = pkgs.writeShellApplication {
    name = "render-vikunja-env";
    runtimeInputs = [ python ];
    text = ''
      exec ${python}/bin/python ${scriptsDir}/render-vikunja-env.py
    '';
  };

  healthcheck = pkgs.writeShellApplication {
    name = "vikunja-healthcheck";
    runtimeInputs = [ pkgs.curl pkgs.jq ];
    text = ''
      exec ${pkgs.bash}/bin/bash ${scriptsDir}/vikunja-healthcheck
    '';
  };

  mcpConfig = pkgs.writeText "vikunja-mcp.config.json" (builtins.toJSON {
    logging.level = "warn";
    modules = {
      tasks = true;
      projects = true;
      labels = true;
      notifications = true;
      teams = false;
      users = false;
      webhooks = false;
      filters = false;
      templates = false;
      export = false;
      batchImport = false;
      subscriptions = false;
      reactions = false;
      admin = false;
      tokenManagement = false;
      caldavTokens = false;
      userDeletion = false;
      backgrounds = false;
    };
  });

  mcp = pkgs.writeShellApplication {
    name = "vikunja-mcp";
    runtimeInputs = [ pkgs.nodejs_24 ];
    text = ''
      set -euo pipefail

      token_file="${cfg.secretsDir}/mcp-api-token"
      if [[ ! -s "$token_file" ]]; then
        echo "Vikunja MCP token file is missing or empty: $token_file" >&2
        exit 1
      fi

      export VIKUNJA_URL="http://127.0.0.1:${toString cfg.port}/api/v1"
      VIKUNJA_API_TOKEN="$(<"$token_file")"
      export VIKUNJA_API_TOKEN
      export VIKUNJA_MCP_CONFIG="${mcpConfig}"
      export NODE_ENV=production

      exec ${pkgs.nodejs_24}/bin/npx --yes "vikunja-mcp-ng@${cfg.mcp.packageVersion}"
    '';
  };

  backup = pkgs.writeShellApplication {
    name = "vikunja-backup";
    runtimeInputs = [ pkgs.docker pkgs.postgresql pkgs.gnutar pkgs.findutils pkgs.coreutils ];
    text = ''
      export VIKUNJA_STATE_DIR="${cfg.stateDir}"
      export VIKUNJA_SECRETS_DIR="${cfg.secretsDir}"
      export VIKUNJA_COMPOSE_PROJECT="${cfg.composeProject}"
      export VIKUNJA_COMPOSE_FILE="${composeFile}"
      export VIKUNJA_ENV_FILE="${cfg.stateDir}/vikunja.env"
      exec ${pkgs.bash}/bin/bash ${scriptsDir}/vikunja-backup
    '';
  };

  supervisor = pkgs.writeShellApplication {
    name = "vikunja-supervisor";
    runtimeInputs = [ pkgs.docker renderer healthcheck pkgs.coreutils ];
    text = ''
      set -euo pipefail
      umask 077

      ${renderer}/bin/render-vikunja-env >/dev/null
      until ${pkgs.docker}/bin/docker info >/dev/null 2>&1; do
        sleep 2
      done

      compose() {
        ${pkgs.docker}/bin/docker compose \
          --project-name "$VIKUNJA_COMPOSE_PROJECT" \
          --env-file "$VIKUNJA_ENV_FILE" \
          --file ${composeFile} \
          "$@"
      }

      compose up -d --no-build
      for _ in $(seq 1 60); do
        if ${healthcheck}/bin/vikunja-healthcheck; then
          break
        fi
        sleep 2
      done
      ${healthcheck}/bin/vikunja-healthcheck || {
        echo "Vikunja did not become healthy" >&2
        exit 1
      }

      while sleep 15; do
        if [[ -z "$(compose ps --status running --quiet vikunja)" ]] || [[ -z "$(compose ps --status running --quiet db)" ]]; then
          compose up -d --no-build
        fi
      done
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
  options.${namespace}.productivity.vikunja = {
    enable = mkBoolOpt false "Install Nix-managed Vikunja service definitions.";

    productionActive = mkBoolOpt false "Allow the Vikunja agents to start automatically.";

    stateDir = mkOption {
      type = types.str;
      default = "${userCfg.home}/Library/Application Support/Vikunja";
      description = "User-owned Vikunja state: rendered environment, files, backups, and logs; PostgreSQL uses the isolated Compose volume.";
    };

    secretsDir = mkOption {
      type = types.str;
      default = "${userCfg.home}/.config/sops-nix/secrets/vikunja";
      description = "Directory of SOPS-materialized Vikunja secret files.";
    };

    composeProject = mkOption {
      type = types.str;
      default = "vikunja";
      description = "Docker Compose project name for the isolated Vikunja deployment.";
    };

    port = mkOption {
      type = types.port;
      default = 3456;
      description = "Loopback HTTP port for Vikunja.";
    };

    publicBase = mkOption {
      type = types.str;
      default = "https://olisikh-mini.bandicoot-scala.ts.net";
      description = "Tailnet HTTPS origin Vikunja emits in browser and API responses.";
    };

    vikunjaImageTag = mkOption {
      type = types.str;
      default = "2.3.0";
      description = "Pinned Vikunja Community image tag.";
    };

    postgresImageTag = mkOption {
      type = types.str;
      default = "18.3";
      description = "Pinned PostgreSQL image tag used only by Vikunja.";
    };

    mcp = {
      enable = mkBoolOpt false "Install the Hermes-owned Vikunja MCP stdio adapter.";

      packageVersion = mkOption {
        type = types.str;
        default = "0.5.2";
        description = "Pinned vikunja-mcp-ng npm package version launched by the stdio adapter.";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ backup ] ++ lib.optionals cfg.mcp.enable [ mcp ];

    launchd.user.agents = {
      vikunja = {
        path = [ config.environment.systemPath ];
        serviceConfig = productionServiceConfig "com.olisikh.vikunja-nix" "${supervisor}/bin/vikunja-supervisor";
      };

      vikunja-backup = {
        path = [ config.environment.systemPath ];
        serviceConfig = (productionServiceConfig "com.olisikh.vikunja-backup" "${backup}/bin/vikunja-backup") // {
          KeepAlive = false;
          RunAtLoad = false;
          StartCalendarInterval = [
            {
              Hour = 3;
              Minute = 17;
            }
          ];
        };
      };
    };
  };
}
