{ pkgs, ... }:

pkgs.vimUtils.buildVimPlugin {
  name = "nvim-java";
  src = pkgs.fetchFromGitHub {
    owner = "olisikh";
    repo = "nvim-java";
    rev = "d5db275b7649f4377fb7527daa9002f7bf212a09";
    hash = "sha256-5wkHJCFYB7pkDKU6EJ3UvTCKvCZiKkdWt7ypne1Yx04=";
  };
  dependencies = with pkgs.vimPlugins; [
    nui-nvim
    nvim-dap
    nvim-lspconfig
  ];
}
