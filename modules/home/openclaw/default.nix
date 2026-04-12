{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.openclaw;

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

    agents.defaults.memorySearch.remote.apiKey = mkEnvSecretRef "gemini" "GEMINI_API_KEY";

    plugins.entries.google.config.webSearch.apiKey = mkEnvSecretRef "gemini" "GEMINI_API_KEY";

    messages.tts.providers.elevenlabs.apiKey = mkEnvSecretRef "elevenlabs" "ELEVENLABS_API_KEY";

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
    # NOTE: Upstream currently merges instance config over global config, and the
    # default instance config expands to many null fields, which can erase the
    # global config after stripNulls. Put our full config on the default instance.
    # Keep top-level config empty to avoid being overwritten.
    programs.openclaw = {
      enable = true;
      inherit (cfg) documents bundledPlugins customPlugins excludeTools;
      config = { };
      instances.default.config = recursiveUpdate (recursiveUpdate cfg.config cfg.extraConfig) secretConfig;

      # NOTE: Work around nix-openclaw default-instance appDefaults bug by setting nixMode explicitly.
      instances.default.appDefaults.nixMode = lib.mkDefault true;
    };

    # NOTE: OpenClaw may rewrite this file at runtime. Keep Home Manager authoritative.
    home.file.".openclaw/openclaw.json".force = lib.mkDefault true;

    home.activation.openclawLoadSecretEnv = mkIf (pkgs.stdenv.isDarwin) (lib.mkAfter ''
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
