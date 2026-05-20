{ pkgs, ... }:

pkgs.vimUtils.buildVimPlugin {
  name = "nvim-java";
  src = pkgs.fetchFromGitHub {
    owner = "olisikh";
    repo = "nvim-java";
    rev = "6739851e2316a9fb1b9997986978b4a36c795462";
    hash = "sha256-ImvffGAeUjKgmXFNMWyZHDI7bsWnXG3yFZJIDmUVBGw=";
  };
  dependencies = with pkgs.vimPlugins; [
    nui-nvim
    nvim-dap
    nvim-lspconfig
  ];
}
