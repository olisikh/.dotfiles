{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf optionalAttrs recursiveUpdate types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.openclaw;

  gatewayTokenProvider = "gatewayToken";

  telegramBotTokenSecretPath = "${cfg.sopsSecretsDir}/${cfg.telegramBotTokenSopsName}";

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

        secrets.providers = {
          "${gatewayTokenProvider}" = {
            source = "env";
            allowlist = [ "OPENCLAW_GATEWAY_TOKEN" ];
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
      telegramBotTokenSopsName = mkOpt str "openclawTelegramBotToken" "sops secret filename containing Telegram bot token";
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
