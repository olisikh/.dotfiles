{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.dev.kafka;
in
{
  options.${namespace}.dev.kafka = {
    enable = lib.${namespace}.mkBoolOpt false "Enable Kafka tools (kafkactl)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.kafkactl ];

    programs.zsh.initContent = lib.${namespace}.mkZshLate
      # zsh
      ''
        eval "$(kafkactl completion zsh)"
      '';
  };
}
