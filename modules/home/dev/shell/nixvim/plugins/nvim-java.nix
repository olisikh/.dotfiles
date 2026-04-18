{ pkgs, lib, namespace, config, hmConfig, ... }:
let
  cfg = hmConfig.${namespace}.dev.shell.nixvim.plugins.nvim-java;

  nvimJavaPackageRoots = {
    jdtls = "${pkgs.jdt-language-server}/share/java/jdtls";

    java-test = pkgs.runCommand "nvim-java-java-test" { } ''
      mkdir -p "$out"
      ln -s ${pkgs.vscode-extensions.vscjava.vscode-java-test}/share/vscode/extensions/vscjava.vscode-java-test "$out/extension"
    '';

    java-debug = pkgs.runCommand "nvim-java-java-debug" { } ''
      mkdir -p "$out"
      ln -s ${pkgs.vscode-extensions.vscjava.vscode-java-debug}/share/vscode/extensions/vscjava.vscode-java-debug "$out/extension"
    '';

    lombok = pkgs.runCommand "nvim-java-lombok-${pkgs.lombok.version}" { } ''
      mkdir -p "$out"
      ln -s ${pkgs.lombok}/share/java/lombok.jar "$out/lombok.jar"
    '';

    openjdk = pkgs.runCommand "nvim-java-openjdk-25" { } ''
      mkdir -p "$out/jdk-nix/Contents"
      ln -s ${pkgs.jdk25} "$out/jdk-nix/Contents/Home"
      ln -s ${pkgs.jdk25}/bin "$out/jdk-nix/bin"
    '';
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
    extraPlugins = with pkgs.vimPlugins; [ nvim-java spring-boot ];

    extraConfigLua = ''
      local nvim_java_package_roots = {
        jdtls = "${nvimJavaPackageRoots.jdtls}",
        ['java-test'] = "${nvimJavaPackageRoots.java-test}",
        ['java-debug'] = "${nvimJavaPackageRoots.java-debug}",
        lombok = "${nvimJavaPackageRoots.lombok}",
        openjdk = "${nvimJavaPackageRoots.openjdk}",
      }

      do
        local Manager = require("pkgm.manager")
        local original_get_install_dir = Manager.get_install_dir

        function Manager:install(name, version)
          local package_root = nvim_java_package_roots[name]
          if package_root ~= nil then
            return package_root
          end

          error(("nvim-java tried to install unmanaged package %q version %q"):format(name, version))
        end

        function Manager:get_install_dir(name, version)
          local package_root = nvim_java_package_roots[name]
          if package_root ~= nil then
            return package_root
          end

          return original_get_install_dir(self, name, version)
        end
      end

      require("java").setup({
        spring_boot_tools = {
          enable = false
        },
        jdk = {
          auto_install = false,
          version = "25"
        }
      });
    '';

    plugins.lsp.servers.jdtls.enable = true;
  };
}
