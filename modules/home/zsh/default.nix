{ config, lib, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.zsh;

  catppuccinZshTheme = pkgs.fetchFromGitHub {
    "owner" = "catppuccin";
    "repo" = "zsh-syntax-highlighting";
    "rev" = "06d519c20798f0ebe275fc3a8101841faaeee8ea";
    "sha256" = "sha256-Q7KmwUd9fblprL55W0Sf4g7lRcemnhjh4/v+TacJSfo=";
  };
in
{
  options.${namespace}.zsh = {
    enable = mkBoolOpt false "Enable zsh program";
  };

  config = mkIf cfg.enable {
    home.file = {
      ".config/zsh/catppuccin".source = catppuccinZshTheme;
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;

      initExtraBeforeCompInit =
        #bash
        ''
          # init completions
          autoload -U +X bashcompinit && bashcompinit
          autoload -U +X compinit && compinit
        '';

      initExtra =
        #bash
        ''
          source ${catppuccinZshTheme}/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
          eval "$(kafkactl completion zsh)"
          eval "$(fzf --zsh)"

          # Preferred editor for local and remote sessions
          if [[ -n $SSH_CONNECTION ]]; then
            export EDITOR='vi'
          else
            export EDITOR='nvim'
          fi

          bindkey -e # enable emacs mode
          bindkey '^p' history-search-backward
          bindkey '^n' history-search-forward

          # history settings
          HISTSIZE=1000
          HISTFILE=~/.zsh_history
          SAVEHIST=$HISTSIZE
          HISTDUP=erase
          setopt appendhistory
          setopt sharehistory
          setopt hist_ignore_space
          setopt hist_ignore_all_dups
          setopt hist_save_no_dups
          setopt hist_ignore_dups
          setopt hist_find_no_dups

          # extra plugin settings
          zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
          # zstyle ':completion:*' list-colors $${(s.:.)LS_COLORS}
          zstyle ':completion:*' menu no
          zstyle ':fzf-tab:complete:*' fzf-preview 'ls $realpath'

          export LIBRARY_PATH="${pkgs.libiconv}/lib:$LIBRARY_PATH";

          alias tf=terraform
          alias k=kubectl

          # smart cd
          alias zz="z -"

          # smart ls
          alias ls="exa"
          alias ll="exa -alh"
          alias tree="exa --tree"


          # overrides for work
          [[ -s "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
        '';

      antidote = {
        enable = true;
        useFriendlyNames = true;

        plugins = [
          "rupa/z"
          "zsh-users/zsh-completions"
          "zsh-users/zsh-autosuggestions"
          "zsh-users/zsh-syntax-highlighting"
          "chisui/zsh-nix-shell"
          "nix-community/nix-zsh-completions"
          "ohmyzsh/ohmyzsh path:plugins/git"
          "Aloxaf/fzf-tab"
        ];
      };
    };
  };
}
