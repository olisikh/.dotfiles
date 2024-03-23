catppuccinFlavour: { inputs, lib, config, pkgs, ... }:
{
  home. file = {
    ".zsh".source = ~/.dotfiles/zsh;
    ".envrc".text = "use_nix";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;

    initExtraBeforeCompInit = ''
      # init completions
      autoload -U +X bashcompinit && bashcompinit
      autoload -U +X compinit && compinit
    '';

    initExtra = ''
      source ~/.zsh/catppuccin-${catppuccinFlavour}.zsh

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

      alias tf=terraform
      alias k=kubectl

      # smart cd
      alias zz="z -"

      # smart ls
      alias ls="exa"
      alias ll="exa -alh"
      alias tree="exa --tree"
      alias cat="bat -pp"

      # overrides for work
      [[ -s "~/.zshrc.local" ]] && source "~/.zshrc.local"
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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.ripgrep = {
    enable = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      scala.symbol = " ";
      java.symbol = " ";
      nix_shell.symbol = " ";
      nodejs.symbol = " ";
      golang.symbol = " ";
      rust.symbol = " ";
      docker_context.symbol = " ";
      haskell.symbol = " ";
      elixir.symbol = " ";
      lua.symbol = " ";
      terraform.symbol = " ";
      aws.symbol = "  ";
    };
  };

  programs.bat = {
    enable = true;

    themes = {
      catppuccin = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "main";
          sha256 = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
        };
        file = "Catppuccin-${catppuccinFlavour}.tmTheme";
      };
    };

    config = {
      theme = "catppuccin";
    };
  };
}
