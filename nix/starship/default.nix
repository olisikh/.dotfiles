{ ... }: { pkgs, ... }:
{
  home.packages = with pkgs; [
    starship
  ];

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
}
