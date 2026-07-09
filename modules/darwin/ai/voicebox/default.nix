{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.voicebox;
  userCfg = config.${namespace}.core.user;
in
{
  options.${namespace}.ai.voicebox = {
    enable = mkBoolOpt false "Enable voicebox (local AI voice studio server)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.${namespace}.voicebox;
      description = "Voicebox package to use.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address the Voicebox server will bind to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 17493;
      description = "Port on which the Voicebox server will listen.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "${userCfg.home}/Library/Application Support/Voicebox";
      description = "Directory for the Voicebox database, profiles, captures, and generations.";
    };

    modelsDir = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.dataDir}/models";
      description = "Directory for Hugging Face model downloads.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    system.activationScripts.voicebox.text = ''
      mkdir -p "${cfg.dataDir}/logs"
    '';

    launchd.user.agents.voicebox = {
      path = [ config.environment.systemPath ];

      serviceConfig = {
        Label = "sh.voicebox.server";
        KeepAlive = true;
        RunAtLoad = true;
        WorkingDirectory = cfg.dataDir;

        ProgramArguments = [
          "${cfg.package}/bin/voicebox-server"
          "--host"
          cfg.host
          "--port"
          (toString cfg.port)
          "--data-dir"
          cfg.dataDir
        ];

        EnvironmentVariables = {
          VOICEBOX_MODELS_DIR = cfg.modelsDir;
        };

        StandardOutPath = "${cfg.dataDir}/logs/voicebox.stdout.log";
        StandardErrorPath = "${cfg.dataDir}/logs/voicebox.stderr.log";
      };
    };
  };
}
