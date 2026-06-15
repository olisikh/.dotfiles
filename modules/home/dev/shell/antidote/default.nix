{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}.zsh) mkMid;

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
        # fpath additions must come before compinit
        "zsh-users/zsh-completions"
        "nix-community/nix-zsh-completions"
        "chisui/zsh-nix-shell"
        "ohmyzsh/ohmyzsh path:plugins/git"
        "ohmyzsh/ohmyzsh path:plugins/aws"
        "ohmyzsh/ohmyzsh path:plugins/kubectl"
        "ohmyzsh/ohmyzsh path:plugins/terraform"
        # ez-compinit calls compinit at the right point
        "mattmc3/ez-compinit"
        # fzf-tab must come after compinit, before widget wrappers
        "Aloxaf/fzf-tab"
        # widget wrappers must come after fzf-tab
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-syntax-highlighting"
      ];
    };

    programs.zsh.initContent = mkMid
      # zsh
      ''
        zstyle ':fzf-tab:*' use-fzf-default-opts yes
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
      '';

    home.sessionVariables = {
      ANTIDOTE_HOME = "${config.home.homeDirectory}/.cache/antidote";
    };
  };
}
