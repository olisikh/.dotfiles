{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.ollama;
  userCfg = config.${namespace}.user;

  ollamaDir = "${userCfg.home}/.ollama";
in
{
  options.${namespace}.services.ollama = {
    enable = mkBoolOpt false "Enable ollama module";
    port = lib.mkOption {
      type = lib.types.port;
      default = 11434;
      description = "Port on which the ollama service will listen.";
    };
  };

  config = mkIf cfg.enable {
    environment = {
      systemPath = [ "/opt/homebrew/bin" ];
    };

    launchd.user.agents.ollama = {
      path = [ config.environment.systemPath ];

      serviceConfig = {
        Label = "org.ollama.default";
        KeepAlive = true;
        RunAtLoad = true;
        ProgramArguments = [ "/opt/homebrew/bin/ollama" "serve" ];

        StandardOutPath = "${ollamaDir}/ollama.stdout.log";
        StandardErrorPath = "${ollamaDir}/ollama.stderr.log";
      };
    };
  };
}
