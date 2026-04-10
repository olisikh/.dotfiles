{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.openclaw;

  gatewayTokenProvider = "gatewayToken";
  geminiApiKeyProvider = "geminiApiKey";
  elevenlabsApiKeyProvider = "elevenlabsApiKey";

  gatewayTokenSecretPath = "${cfg.sopsSecretsDir}/${cfg.sops.gatewayToken}";
  telegramBotTokenSecretPath = "${cfg.sopsSecretsDir}/${cfg.sops.telegramBotToken}";
  memoryApiKeySecretPath = "${cfg.sopsSecretsDir}/${cfg.sops.memorySearchApiKey}";
  elevenlabsApiKeySecretPath = "${cfg.sopsSecretsDir}/${cfg.sops.elevenlabsApiKey}";

  mkEnvSecretRef = provider: id: {
    source = "env";
    inherit provider id;
  };

  secretConfig =
    if !cfg.useSopsSecrets then
      { }
    else
      {
        channels.telegram.tokenFile = telegramBotTokenSecretPath;

        gateway.auth.token = mkEnvSecretRef gatewayTokenProvider "OPENCLAW_GATEWAY_TOKEN";

        agents.defaults.memorySearch.remote.apiKey = mkEnvSecretRef geminiApiKeyProvider "GEMINI_API_KEY";

        plugins.entries.google.config.webSearch.apiKey = mkEnvSecretRef geminiApiKeyProvider "GEMINI_API_KEY";

        messages.tts.providers.elevenlabs.apiKey = mkEnvSecretRef elevenlabsApiKeyProvider "ELEVENLABS_API_KEY";

        secrets.providers = {
          "${gatewayTokenProvider}" = {
            source = "env";
            allowlist = [ "OPENCLAW_GATEWAY_TOKEN" ];
          };
          "${geminiApiKeyProvider}" = {
            source = "env";
            allowlist = [ "GEMINI_API_KEY" ];
          };
          "${elevenlabsApiKeyProvider}" = {
            source = "env";
            allowlist = [ "ELEVENLABS_API_KEY" ];
          };
        };
      };
in
{
  options.${namespace}.openclaw = with types;
    {
      enable = mkBoolOpt false "Enable OpenClaw via nix-openclaw Home Manager module";

      config = mkOpt attrs { } "OpenClaw config attrset (openclaw.json in Nix format), provided by each host";
      extraConfig = mkOpt attrs { } "Additional OpenClaw config recursively merged over openclaw.config";

      documents = mkOpt (nullOr path) null "Optional directory with AGENTS.md/SOUL.md/TOOLS.md for OpenClaw workspace bootstrap";
      bundledPlugins = mkOpt attrs { } "Optional overrides for programs.openclaw.bundledPlugins";
      customPlugins = mkOpt (listOf attrs) [ ] "Extra programs.openclaw.customPlugins entries";
      excludeTools = mkOpt (listOf str) [ "nodejs_22" "python3" ] "OpenClaw bundled tool names to exclude (defaults avoid /bin/node and python collisions with user toolchain)";

      useSopsSecrets = mkBoolOpt true "Inject secret refs/token files from sops-nix decrypted files";
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
        description = "SOPS secret names used by the service.";
      };
    };

  config = mkIf cfg.enable {
    programs.openclaw = {
      enable = true;
      inherit (cfg) documents bundledPlugins customPlugins excludeTools;
      config = recursiveUpdate (recursiveUpdate cfg.config cfg.extraConfig) secretConfig;

      # NOTE: Work around nix-openclaw default-instance appDefaults bug by setting nixMode explicitly.
      instances.default.appDefaults.nixMode = lib.mkDefault true;
    };

    home.activation.openclawLoadSecretEnv = mkIf (cfg.useSopsSecrets && pkgs.stdenv.isDarwin) (lib.mkAfter ''
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
