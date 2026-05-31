{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}.zsh) mkEarly;

  cfg = config.${namespace}.dev.shell.antidote;
  zshCfg = config.${namespace}.dev.shell.zsh;
in
{
  options.${namespace}.dev.shell.antidote = {
    enable = lib.${namespace}.mkBoolOpt false "Enable Antidote (zsh plugin manager)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = zshCfg.enable;
      message = "Antidote requires zsh to be enabled (dev.shell.zsh.enable = true)";
    }];

    programs.zsh.antidote = {
      enable = true;
      useFriendlyNames = true;

      plugins = [
        "zsh-users/zsh-completions"
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-syntax-highlighting"
        "chisui/zsh-nix-shell"
        "nix-community/nix-zsh-completions"
        "ohmyzsh/ohmyzsh path:plugins/git"
        "ohmyzsh/ohmyzsh path:plugins/aws"
        "ohmyzsh/ohmyzsh path:plugins/kubectl"
        "ohmyzsh/ohmyzsh path:plugins/terraform"
        "Aloxaf/fzf-tab"
      ];
    };

    programs.zsh.initContent = mkEarly
      # zsh
      ''
        zstyle ':fzf-tab:*' use-fzf-default-opts yes
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
      '';
  };
}
