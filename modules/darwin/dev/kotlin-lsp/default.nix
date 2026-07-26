{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.kotlin-lsp;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.dev.kotlin-lsp = {
    enable = mkBoolOpt false "Enable Kotlin LSP server (JetBrains/utils/kotlin-lsp Homebrew formula)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "kotlin-lsp requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.brews = [ "JetBrains/utils/kotlin-lsp" ];
  };
}