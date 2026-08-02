{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  inherit (lib.${namespace}.zsh) mkLate;

  cfg = config.${namespace}.ai.opencode2;

  # opencode2 service config: hostname, port, password
  # Written to ~/.config/opencode/service.json
  serviceConfig = lib.optionalAttrs (cfg.service.hostname != null) { hostname = cfg.service.hostname; }
    // lib.optionalAttrs (cfg.service.port != null) { port = cfg.service.port; }
    // lib.optionalAttrs (cfg.service.passwordFile != null) { password = "!cat ${cfg.service.passwordFile}"; };
in
{
  options.${namespace}.ai.opencode2 = {
    enable = mkBoolOpt false "Enable OpenCode 2 preview CLI";

    service = {
      hostname = mkOpt (types.nullOr types.str) null ''
        Hostname for the background server. Use "0.0.0.0" to listen on all interfaces.
      '';

      port = mkOpt (types.nullOr types.ints.unsigned) null ''
        Port for the background server (1-65535).
      '';

      passwordFile = mkOpt (types.nullOr types.path) null ''
        Path to a file containing the service password.
        The value is read at runtime via "!cat <path>".
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.opencode2 ];

    programs.zsh.initContent = mkLate
      # zsh
      ''
        eval "$(opencode2 --completions zsh 2>/dev/null)"
      '';

    home.file = {
      # Background server config (hostname, port, password)
      ".config/opencode/service.json" = mkIf (serviceConfig != { }) {
        text = builtins.toJSON serviceConfig;
      };
    };
  };
}
