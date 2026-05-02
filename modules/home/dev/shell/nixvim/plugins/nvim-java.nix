{ pkgs, lib, namespace, hmConfig, ... }:
let
  cfg = hmConfig.${namespace}.dev.shell.nixvim.plugins.nvim-java;

  springBootTools = pkgs.${namespace}.vscode-spring-boot;

  springBootToolsPath =
    if cfg.tools.spring-boot-tools.path != null
    then cfg.tools.spring-boot-tools.path
    else "${springBootTools}/share/vscode/extensions/vmware.vscode-spring-boot";
in
{
  config = lib.mkIf cfg.enable {
    extraPlugins = with pkgs.${namespace}; [ nvim-java nvim-spring-boot ];

    extraConfigLua = ''
      require("java").setup({
        jdtls = {
          path = "${cfg.tools.jdtls.path}",
          auto_install = false
        },
        lombok = {
          path = "${cfg.tools.lombok.path}",
          auto_install = false
        },
        java_test = {
          path = "${cfg.tools.java-test.path}",
          auto_install = false
        },
        java_debug_adapter = {
          path = "${cfg.tools.java-debug.path}",
          auto_install = false
        },
        spring_boot_tools = {
          path = "${springBootToolsPath}",
          auto_install = false
        },
        jdk = {
          path = "${cfg.tools.jdk.path}",
          auto_install = false,
          version = "${cfg.tools.jdk.version}"
        }
      });
    '';

    plugins.lsp.servers.jdtls.enable = true;
  };
}
