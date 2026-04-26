{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.ai.openclaw;

  stateDir = "${config.home.homeDirectory}/.openclaw";
  workspaceDir = "${stateDir}/workspace";

  gatewayTokenSecretPath = "${cfg.sopsSecretsDir}/${cfg.sops.gatewayToken}";
  telegramBotTokenSecretPath = "${cfg.sopsSecretsDir}/${cfg.sops.telegramBotToken}";
  memoryApiKeySecretPath = "${cfg.sopsSecretsDir}/${cfg.sops.memorySearchApiKey}";
  elevenlabsApiKeySecretPath = "${cfg.sopsSecretsDir}/${cfg.sops.elevenlabsApiKey}";

  mkEnvSecretRef = provider: id: {
    source = "env";
    inherit provider id;
  };

  secretConfig = {
    channels.telegram.tokenFile = telegramBotTokenSecretPath;

    gateway.auth.token = mkEnvSecretRef "gateway" "OPENCLAW_GATEWAY_TOKEN";

    agents.defaults.workspace = workspaceDir;
    agents.defaults.memorySearch.remote.apiKey = mkEnvSecretRef "gemini" "GEMINI_API_KEY";

    plugins.entries.google.config.webSearch.apiKey = mkEnvSecretRef "gemini" "GEMINI_API_KEY";

    secrets.providers = {
      gateway = {
        source = "env";
        allowlist = [ "OPENCLAW_GATEWAY_TOKEN" ];
      };
      gemini = {
        source = "env";
        allowlist = [ "GEMINI_API_KEY" ];
      };
      elevenlabs = {
        source = "env";
        allowlist = [ "ELEVENLABS_API_KEY" ];
      };
    };
  };

  mergedConfig = recursiveUpdate cfg.config secretConfig;
  openclawConfigFile = pkgs.writeText "openclaw.json" (builtins.toJSON mergedConfig);
in
{
  options.${namespace}.ai.openclaw = with types; {
    enable = mkBoolOpt false "Manage OpenClaw config files and secret env vars";

    config = mkOpt attrs { } "OpenClaw config attrset written to ~/.openclaw/openclaw.json";

    sopsSecretsDir = mkOpt str "${config.home.homeDirectory}/.config/sops-nix/secrets" "Directory where sops-nix writes decrypted secrets";

    sops = lib.mkOption {
      type = types.submodule {
        options = {
          memorySearchApiKey =
            mkOpt types.str "gemini" "sops secret filename containing Gemini API key";

          elevenlabsApiKey =
            mkOpt types.str "elevenlabs" "sops secret filename containing ElevenLabs API key";

          telegramBotToken =
            mkOpt types.str "openclawTelegramBotToken" "sops secret filename containing Telegram bot token";

          gatewayToken =
            mkOpt types.str "openclawGatewayToken" "sops secret filename containing OpenClaw gateway token";
        };
      };
      default = { };
      description = "SOPS secret names used by OpenClaw.";
    };
  };

  config = mkIf cfg.enable {
    home.file.".openclaw/openclaw.json" = {
      source = openclawConfigFile;
      force = true;
    };

    home.activation.openclawLoadSecretEnv = mkIf pkgs.stdenv.isDarwin (lib.mkAfter ''
      if [ -f "${gatewayTokenSecretPath}" ] && [ -s "${gatewayTokenSecretPath}" ]; then
        /bin/launchctl setenv OPENCLAW_GATEWAY_TOKEN "$(${lib.getExe' pkgs.coreutils "cat"} "${gatewayTokenSecretPath}")"
      fi
      if [ -f "${memoryApiKeySecretPath}" ] && [ -s "${memoryApiKeySecretPath}" ]; then
        /bin/launchctl setenv GEMINI_API_KEY "$(${lib.getExe' pkgs.coreutils "cat"} "${memoryApiKeySecretPath}")"
      fi
      if [ -f "${elevenlabsApiKeySecretPath}" ] && [ -s "${elevenlabsApiKeySecretPath}" ]; then
        /bin/launchctl setenv ELEVENLABS_API_KEY "$(${lib.getExe' pkgs.coreutils "cat"} "${elevenlabsApiKeySecretPath}")"
      fi
    '');
  };
}
