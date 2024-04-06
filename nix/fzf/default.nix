{ theme, themeStyle, ... }: { pkgs, ... }:
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    colors = {
      "bg" = "#1e1e2e";
      "bg+" = "#313244";
      "fg" = "#cdd6f4";
      "fg+" = "#cdd6f4";
      "spinner" = "#f5e0dc";
      "hl" = "#f38ba8";
      "hl+" = "#f38ba8";
      "header" = "#f38ba8";
      "info" = "#cba6f7";
      "pointer" = "#f5e0dc";
      "marker" = "#f5e0dc";
      "prompt" = "#cba6f7";
    };
    tmux = {
      enableShellIntegration = true;
    };
  };
}
