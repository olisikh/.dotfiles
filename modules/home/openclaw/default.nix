{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf optionalAttrs recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.openclaw;

  gatewayTokenProvider = "gatewayToken";
  geminiApiKeyProvider = "geminiApiKey";

  gatewayTokenSecretPath = "${cfg.sopsSecretsDir}/${cfg.gatewayTokenSopsName}";
  telegramBotTokenSecretPath = "${cfg.sopsSecretsDir}/${cfg.telegramBotTokenSopsName}";
  memoryApiKeySecretPath = "${cfg.sopsSecretsDir}/${cfg.memorySearchApiKeySopsName}";

  mkFileSecretRef = provider: id: {
    source = "file";
    inherit provider id;
  };

  secretConfig =
    if !cfg.injectSecrets then { }
    else if cfg.useSopsSecrets then
      {
        channels.telegram.tokenFile = telegramBotTokenSecretPath;

        gateway.auth.token = mkFileSecretRef gatewayTokenProvider "value";

        agents.defaults.memorySearch.remote.apiKey = mkFileSecretRef geminiApiKeyProvider "value";

        plugins.entries.google.config.webSearch.apiKey = mkFileSecretRef geminiApiKeyProvider "value";

        secrets.providers = {
          "${gatewayTokenProvider}" = {
            source = "file";
            path = gatewayTokenSecretPath;
            mode = "singleValue";
          };
          "${geminiApiKeyProvider}" = {
            source = "file";
            path = memoryApiKeySecretPath;
            mode = "singleValue";
          };
        };
      }
    else
      { };
in
{
  options.${namespace}.openclaw = with types; {
    enable = mkBoolOpt false "Enable OpenClaw via nix-openclaw Home Manager module";

    config = mkOpt attrs { } "OpenClaw config attrset (openclaw.json in Nix format), provided by each host";
    extraConfig = mkOpt attrs { } "Additional OpenClaw config recursively merged over openclaw.config";

    documents = mkOpt (nullOr path) null "Optional directory with AGENTS.md/SOUL.md/TOOLS.md for OpenClaw workspace bootstrap";
    bundledPlugins = mkOpt attrs { } "Optional overrides for programs.openclaw.bundledPlugins";
    customPlugins = mkOpt (listOf attrs) [ ] "Extra programs.openclaw.customPlugins entries";
    excludeTools = mkOpt (listOf str) [ "nodejs_22" "python3" ] "OpenClaw bundled tool names to exclude (defaults avoid /bin/node and python collisions with user toolchain)";

    useSopsSecrets = mkBoolOpt true "Inject secret refs/token files from sops-nix decrypted files";
    injectSecrets = mkBoolOpt true "Inject gateway/token/memory-search secret refs into the OpenClaw config";
    sopsSecretsDir = mkOpt str "${config.home.homeDirectory}/.config/sops-nix/secrets" "Directory where sops-nix writes decrypted secrets";
    memorySearchApiKeySopsName = mkOpt str "gemini" "sops secret filename containing Gemini API key";
    telegramBotTokenSopsName = mkOpt str "openclawTelegramBotToken" "sops secret filename containing Telegram bot token";
    gatewayTokenSopsName = mkOpt str "openclawGatewayToken" "sops secret filename containing OpenClaw gateway token";
  };

  config = mkIf cfg.enable {
    programs.openclaw = {
      enable = true;
      inherit (cfg) documents bundledPlugins customPlugins excludeTools;
      config = recursiveUpdate (recursiveUpdate cfg.config cfg.extraConfig) secretConfig;

      # NOTE: Work around nix-openclaw default-instance appDefaults bug by setting nixMode explicitly.
      instances.default.appDefaults.nixMode = lib.mkDefault true;
    };
  };
}
