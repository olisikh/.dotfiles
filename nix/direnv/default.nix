{ ... }:
{
  home.file = {
    ".envrc".text = "use_nix";
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };
}
