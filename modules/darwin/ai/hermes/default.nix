{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.hermes;
  toYaml = (pkgs.formats.yaml { }).generate;
  managedConfig = toYaml "hermes-managed-config.yaml" {
    plugins.enabled = cfg.managedPlugins;
  };
in
{
  options.${namespace}.ai.hermes = {
    enable = mkBoolOpt false "Enable Hermes managed system configuration";
    managedPlugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Hermes plugins enabled through the administrator-managed config layer";
    };
  };

  config = mkIf cfg.enable {
    # Hermes merges this root-owned layer over ~/.hermes/config.yaml. Keeping
    # only the managed plugin allow-list here avoids mutating the user config.
    environment.etc."hermes/config.yaml".source = managedConfig;
  };
}
