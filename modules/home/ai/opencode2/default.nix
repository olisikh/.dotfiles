{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (lib.${namespace}.zsh) mkLate;

  cfg = config.${namespace}.ai.opencode2;
in
{
  # NOTE: OpenCode 2 is in beta, uses config of OpenCode 1, config would need migration once OpenCode 1 is no more.
  options.${namespace}.ai.opencode2 = {
    enable = mkBoolOpt false "Enable OpenCode 2 Beta CLI";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.opencode2 ];

    programs.zsh.initContent = mkLate
      # zsh
      ''
        eval "$(opencode2 --completions zsh)"
      '';
  };
}
