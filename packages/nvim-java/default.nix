{ pkgs, ... }:

pkgs.vimUtils.buildVimPlugin {
  name = "nvim-java";
  src = pkgs.fetchFromGitHub {
    owner = "olisikh";
    repo = "nvim-java";
    rev = "602a5f7fa92f9c1d425a2159133ff9de86842f0a";
    hash = "sha256-XdkKm3gE2S2yF8AgZPWO97BE/4yZt0M7pWdTjNKpeM4=";
  };
  dependencies = with pkgs.vimPlugins; [
    nui-nvim
    nvim-dap
    nvim-lspconfig
  ];
}
