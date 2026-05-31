{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}.zsh) mkLate;

  cfg = config.${namespace}.dev.kafka;
in
{
  options.${namespace}.dev.kafka = {
    enable = lib.${namespace}.mkBoolOpt false "Enable Kafka tools (kafkactl)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.kafkactl ];

    programs.zsh.initContent = mkLate
      # zsh
      ''
        eval "$(kafkactl completion zsh)"
      '';
  };
}
