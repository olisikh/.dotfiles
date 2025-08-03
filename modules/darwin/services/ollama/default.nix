{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;

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
      systemPackages = with pkgs; [
        ollama
      ];

      systemPath = [ "${pkgs.ollama}/bin" ];
    };

    launchd.user.agents.ollama = {
      path = [ config.environment.systemPath ];

      serviceConfig = {
        Label = "org.ollama.default";
        KeepAlive = true;
        RunAtLoad = true;
        ProgramArguments = [ "${pkgs.ollama}/bin/ollama" "serve" ];

        StandardOutPath = "${ollamaDir}/ollama.stdout.log";
        StandardErrorPath = "${ollamaDir}/ollama.stderr.log";
      };
    };
  };
}
