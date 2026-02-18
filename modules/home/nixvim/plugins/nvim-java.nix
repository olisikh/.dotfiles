{ pkgs, ... }:
let
  spring-boot = pkgs.vimUtils.buildVimPlugin {
    name = "spring-boot.nvim";
    src = pkgs.fetchFromGitHub {
      owner = "JavaHello";
      repo = "spring-boot.nvim";
      rev = "5d206bdfeb0865ea97bfbc18f9e08e2f26ac4707";
      sha256 = "sha256-ioGlxjZIqtNlPedwI/HX3xA3HOWJ50WmWFyYIQPHDrg="; 
    };
  };
in
{
  extraPlugins = with pkgs.vimPlugins; [ nvim-java spring-boot ];

  extraConfigLua = ''
    require("java").setup();
  '';

  plugins = {
    lsp = {
      enable = true;
      inlayHints = false;
      servers = {
        jdtls.enable = true;
      };
    };
  };
}
