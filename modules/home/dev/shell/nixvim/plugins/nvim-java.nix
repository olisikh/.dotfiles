{ pkgs, lib, namespace, config, hmConfig, ... }:
let
  cfg = hmConfig.${namespace}.dev.shell.nixvim.plugins.nvim-java;

  nvim-java = pkgs.vimUtils.buildVimPlugin {
    name = "nvim-java";
    src = pkgs.fetchFromGitHub {
      owner = "olisikh";
      repo = "nvim-java";
      rev = "4dd43374a5488775e68f0d3548cd9fdea6718307";
      hash = "sha256-5wkHJCFYB7pkDKU6EJ3UvTCKvCZiKkdWt7ypne1Yx04=";
    };
    dependencies = with pkgs.vimPlugins; [
      nui-nvim
      nvim-dap
      nvim-lspconfig
    ];
  };

  # Download and extract vscode-spring-boot extension from Open VSX
  vscode-spring-boot = pkgs.stdenv.mkDerivation rec {
    pname = "vscode-spring-boot";
    version = "1.55.1";

    src = pkgs.fetchurl {
      url = "https://open-vsx.org/api/VMware/vscode-spring-boot/${version}/file/VMware.vscode-spring-boot-${version}.vsix";
      hash = "sha256-wA+VBjEJxXwhptuXBHidbpnCr3KnbtZ1JxJC0FonGHY=";
    };

    nativeBuildInputs = [ pkgs.unzip ];

    unpackPhase = ''
      unzip $src -d vsix-contents
    '';

    installPhase = ''
      mkdir -p $out/share/vscode/extensions/vmware.vscode-spring-boot
      cp -r vsix-contents/extension/* $out/share/vscode/extensions/vmware.vscode-spring-boot/
    '';
  };

  nvimJavaToolPaths = {
    jdk = "${pkgs.jdk25}";
    jdtls = "${pkgs.jdt-language-server}/share/java/jdtls";
    java-test = "${pkgs.vscode-extensions.vscjava.vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test";
    java-debug = "${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug";
    lombok = "${pkgs.lombok}/share/java/lombok.jar";
    spring-boot-tools = "${vscode-spring-boot}/share/vscode/extensions/vmware.vscode-spring-boot";
  };

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
    extraPlugins = [ nvim-java spring-boot ];

    extraConfigLua = ''
      require("java").setup({
        jdtls = {
          path = "${nvimJavaToolPaths.jdtls}",
          auto_install = false
        },
        lombok = {
          path = "${nvimJavaToolPaths.lombok}",
          auto_install = false
        },
        java_test = {
          path = "${nvimJavaToolPaths.java-test}",
          auto_install = false
        },
        java_debug_adapter = {
          path = "${nvimJavaToolPaths.java-debug}",
          auto_install = false
        },
        spring_boot_tools = {
          path = "${nvimJavaToolPaths.spring-boot-tools}",
          auto_install = false
        },
        jdk = {
          path = "${nvimJavaToolPaths.jdk}",
          auto_install = false,
          version = "25"
        }
      });
    '';

    plugins.lsp.servers.jdtls.enable = true;
  };
}
