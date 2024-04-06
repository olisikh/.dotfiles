{ theme, themeStyle, ... }: { pkgs, ... }:
let
  defaultOptions = [
    "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
    "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
    "--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
  ];
in
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions =
      if theme == "catppuccin" then
        if themeStyle == "latte" then [
          "--color=bg+:#ccd0da,bg:#eff1f5,spinner:#dc8a78,hl:#d20f39"
          "--color=fg:#4c4f69,header:#d20f39,info:#8839ef,pointer:#dc8a78"
          "--color=marker:#dc8a78,fg+:#4c4f69,prompt:#8839ef,hl+:#d20f39"
        ]
        else if themeStyle == "frappe" then [
          "--color=bg+:#414559,bg:#303446,spinner:#f2d5cf,hl:#e78284"
          "--color=fg:#c6d0f5,header:#e78284,info:#ca9ee6,pointer:#f2d5cf"
          "--color=marker:#f2d5cf,fg+:#c6d0f5,prompt:#ca9ee6,hl+:#e78284"
        ]
        else if themeStyle == "macchiato" then [
          "--color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796"
          "--color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6"
          "--color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796"
        ]
        else defaultOptions
      else if theme == "tokyonight" then
        if themeStyle == "night" then [
          "--color=fg:#c0caf5,bg:#1a1b26,hl:#ff9e64"
          "--color=fg+:#c0caf5,bg+:#292e42,hl+:#ff9e64"
          "--color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff"
          "--color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a"
        ]
        else if themeStyle == "storm" then [
          "--color=fg:#c0caf5,bg:#24283b,hl:#ff9e64"
          "--color=fg+:#c0caf5,bg+:#292e42,hl+:#ff9e64"
          "--color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff"
          "--color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a"
        ]
        else if themeStyle == "moon" then [
          "--color=fg:#c8d3f5,bg:#222436,hl:#ff966c"
          "--color=fg+:#c8d3f5,bg+:#2f334d,hl+:#ff966c"
          "--color=info:#82aaff,prompt:#86e1fc,pointer:#86e1fc"
          "--color=marker:#c3e88d,spinner:#c3e88d,header:#c3e88d"
        ]
        else [
          "--color=fg:#3760bf,bg:#e1e2e7,hl:#b15c00"
          "--color=fg+:#3760bf,bg+:#c4c8da,hl+:#b15c00"
          "--color=info:#2e7de9,prompt:#007197,pointer:#007197"
          "--color=marker:#587539,spinner:#587539,header:#587539"
        ]
      else defaultOptions;
    tmux = {
      enableShellIntegration = true;
    };
  };
}