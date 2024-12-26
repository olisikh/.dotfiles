{ ... }: {
  programs.nixvim = {
    enable = true;

    # TODO: use nightly?
    # package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;

    colorschemes.catppuccin.enable = true;

    imports = [
      ./plugins.nix
      ./options.nix
      ./keymaps.nix
    ];
  };
}
