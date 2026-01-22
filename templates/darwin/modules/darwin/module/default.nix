{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  # name your module
  cfg = config.${namespace}.module;
in
{
  options.${namespace}.module = {
    enable = mkBoolOpt false "Enable module";

    # options go here...
  };

  config = {
    module = mkIf cfg.enable {
      enable = true;

      # configuration goes here...
    };
  };
}
