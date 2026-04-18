{ pkgs, lib, namespace, config, hmConfig, ... }:
let
  cfg = hmConfig.${namespace}.dev.shell.nixvim.plugins.nvim-java;

  spring-boot = pkgs.vimUtils.buildVimPlugin {
    name = "spring-boot.nvim";
    src = pkgs.fetchFromGitHub {
      owner = "JavaHello";
      repo = "spring-boot.nvim";
      rev = "98c6ff1dcdda943d341bba3c00ae9d190a2e5f7d";
      sha256 = "sha256-JkOWlqyVLcwW7hxOGj5jb8BpUge3bUHbSV0o5qOYW1c=";
    };
  };
in
{
  config = lib.mkIf cfg.enable {
    extraPlugins = with pkgs.vimPlugins; [ nvim-java spring-boot ];

    extraConfigLua = ''
      require("java").setup();
    '';

    plugins.lsp.servers.jdtls.enable = true;
  };
}
