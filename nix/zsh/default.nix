{ themeStyle, ... }: { lib, config, pkgs, ... }:
{
  home.file = {
    ".config/zsh/catppuccin".source = pkgs.fetchFromGitHub {
      "owner" = "catppuccin";
      "repo" = "zsh-syntax-highlighting";
      "rev" = "main";
      "sha256" = "sha256-Q7KmwUd9fblprL55W0Sf4g7lRcemnhjh4/v+TacJSfo=";
    };
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
        source $HOME/.config/zsh/catppuccin/themes/catppuccin_${themeStyle}-zsh-syntax-highlighting.zsh
        eval "$(kafkactl completion zsh)"

        # Preferred editor for local and remote sessions
        if [[ -n $SSH_CONNECTION ]]; then
          export EDITOR='vi'
        else
          export EDITOR='nvim'
        fi

        # Add rust (cargo) executables
        export CARGO_HOME=$HOME/.cargo
        export PATH="$CARGO_HOME/bin:$PATH"

        # Add python bin
        export PYTHON_HOME=$HOME/Library/Python/3.9
        export PATH="$PYTHON_HOME/bin:$PATH"

        alias tf=terraform
        alias k=kubectl
        alias python=python3

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
      ];
    };
  };
}
