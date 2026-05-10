{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.kafka;
in
{
  options.${namespace}.dev.kafka = {
    enable = mkBoolOpt false "Enable Kafka tools (kafkactl)";
  };

  config = mkIf cfg.enable {
    home = {
      packages = [ pkgs.kafkactl ];

      file.".config/zsh/init.d/kafkactl.zsh".text =
        # zsh
        ''
          eval "$(kafkactl completion zsh)"
        '';
    };
  };
}
