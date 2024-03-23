{ ... }: { pkgs, ... }:
{
  home.packages = with pkgs; [
    ripgrep
  ];

  programs.ripgrep = {
    enable = true;
  };
}
