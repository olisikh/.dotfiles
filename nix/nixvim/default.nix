{ ... }: {
  programs.nixvim = {
    enable = true;

    colorschemes.catppuccin.enable = true;

    imports = [
      ./plugins.nix
      ./options.nix
      ./keymaps.nix
    ];

  };
}
