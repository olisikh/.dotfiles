{ catppuccinFlavour, ... }: { pkgs, ... }:
{

  home.packages = with pkgs; [
    tmux
  ];

  home.file = {
    ".config/tmux/plugins/tpm".source = pkgs.fetchFromGitHub {
      owner = "tmux-plugins";
      repo = "tpm";
      rev = "mster";
      sha256 = "sha256-hW8mfwB8F9ZkTQ72WQp/1fy8KL1IIYMZBtZYIwZdMQc=";
    };
  };

  programs.tmux = {
    enable = true;
    clock24 = true;

    extraConfig = builtins.readFile ./tmux.conf;
  };
}
