{ config, lib, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.zsh;

  secrets = lib.attrsets.mapAttrsToList
    (name: value: { inherit name; inherit (value) path; })
    config.sops.secrets;

  exportSecrets =
    lib.foldl'
      (acc: secret:
        acc + "export ${lib.strings.toUpper secret.name}_API_KEY=$(cat ${secret.path});\n"
      )
      ""
      secrets;

  themes = pkgs.fetchFromGitHub {
    "owner" = "catppuccin";
    "repo" = "zsh-syntax-highlighting";
    "rev" = "06d519c20798f0ebe275fc3a8101841faaeee8ea";
    "sha256" = "sha256-Q7KmwUd9fblprL55W0Sf4g7lRcemnhjh4/v+TacJSfo=";
  };


  # NOTE: https://mynixos.com/home-manager/option/programs.zsh.initContent
  # orders are as follows: before = 500, beforeCompInit = 550, default = 1000, after = 1500
  mkBeforeCompInit = lib.mkOrder 550;
  mkDefault = lib.mkOrder 1000;
  mkAfter = lib.mkOrder 1500;
in
{
  options.${namespace}.zsh = {
    enable = mkBoolOpt false "Enable zsh program";
  };

  config = mkIf cfg.enable {
    home.file = {
      ".config/zsh/catppuccin".source = themes;
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;

      dotDir = config.home.homeDirectory;

      initContent =
        let
          zshBefore = mkBeforeCompInit
            # bash
            ''
            '';
          zshDefault = mkDefault
            # bash
            ''
              source ${themes}/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
              eval "$(kafkactl completion zsh)"
              eval "$(fzf --zsh)"
              eval "$(pay-respects zsh)"

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

              # plugin settings
              zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
              zstyle ':completion:*' menu no

              zstyle ':fzf-tab:*' use-fzf-default-opts yes
              zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'

              export LIBRARY_PATH="${pkgs.libiconv}/lib:$LIBRARY_PATH";

              # aliases 
              alias zz="z -"
              alias ls="exa"
              alias ll="exa -alh"
              alias tree="exa --tree"
              alias h="history | fzf | awk '{\$1=\"\"; print substr(\$0, 2)}' | sh"
              alias avante='nvim -c "lua vim.defer_fn(function()require(\"avante.api\").zen_mode()end, 100)"'

              ${exportSecrets}

              # overrides for work
              [[ -s "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
            '';
          zshAfter = mkAfter
            # bash
            ''
            '';
        in
        lib.mkMerge [ zshBefore zshDefault zshAfter ];

      antidote = {
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
    };
  };
}
