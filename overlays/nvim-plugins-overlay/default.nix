{ ... }:
final: prev: {
  vimPlugins = prev.vimPlugins // {
    "99" = final.vimUtils.buildVimPlugin {
      name = "99";
      src = final.fetchFromGitHub {
        owner = "theprimeagen";
        repo = "99";
        rev = "4d229141546290746c82ac90f5afc2786865b5f3";
        hash = "sha256-LQb5jqzTNWVyFNKlICjhnk25fTAmyC38s8/mrOKp//M=";
      };
      doCheck = false;
    };

    harpoon-lualine = final.vimUtils.buildVimPlugin {
      name = "harpoon-lualine";
      src = final.fetchFromGitHub {
        owner = "letieu";
        repo = "harpoon-lualine";
        rev = "215c0847dfb787b19268f7b42eed83bdcf06b966";
        hash = "sha256-HGbz/b2AVl8145BCy8I47dDrhBVMSQQIr+mWbOrmj5Q=";
      };
      dependencies = with final.vimPlugins; [ lualine-nvim ];
    };

    neotest-scala = final.vimUtils.buildVimPlugin {
      name = "neotest-scala";
      src = final.fetchFromGitHub {
        owner = "olisikh";
        repo = "neotest-scala";
        rev = "a7ebaae13f889eac27db54d184a185ccf8a55fd9";
        hash = "sha256-ErR/Anh1vofiI5KBIW1mRkGnEByg+4T75QQJX+csbzw=";
      };
      dependencies = with final.vimPlugins; [
        plenary-nvim
        nvim-nio
        nvim-treesitter-parsers.xml
        neotest
      ];
    };

    neotest-java = final.vimUtils.buildVimPlugin {
      name = "neotest-java";
      src = final.fetchFromGitHub {
        owner = "lucas-garcia-rubio";
        repo = "neotest-java";
        rev = "c8b824acd15f0f7350abf90ab4494e5beee6370c";
        hash = "sha256-HE2IW520SGMh7sK3dOs7IMaV6HRsFXcohQDFyaHBJVw=";
      };
      dependencies = with final.vimPlugins; [ plenary-nvim nvim-nio neotest ];
    };

    neotest-maven = final.vimUtils.buildVimPlugin {
      name = "neotest-maven";
      src = final.fetchFromGitHub {
        owner = "olisikh";
        repo = "neotest-maven";
        rev = "f33a61240c08888f1c1d48d7672402a728f9140d";
        hash = "sha256-40UnjYsPoNjo2MKXcMUTD4a2Z9jlTer3qThawq9E3Wc=";
      };
      dependencies = with final.vimPlugins; [ plenary-nvim nvim-nio neotest ];
    };

    neotest-gradle = final.vimUtils.buildVimPlugin {
      name = "neotest-gradle";
      src = final.fetchFromGitHub {
        owner = "olisikh";
        repo = "neotest-gradle";
        rev = "d7d1b5e53eacf30f535a6aeb22db252405f99536";
        hash = "sha256-ZRI5fMGqKK5BaMPU38Dtl8A+XmWBzBI9af6wld/V0Q0=";
      };
      dependencies = with final.vimPlugins; [ plenary-nvim nvim-nio neotest ];
    };

    nvim-java = final.vimUtils.buildVimPlugin {
      name = "nvim-java";
      src = final.fetchFromGitHub {
        owner = "olisikh";
        repo = "nvim-java";
        rev = "6739851e2316a9fb1b9997986978b4a36c795462";
        hash = "sha256-ImvffGAeUjKgmXFNMWyZHDI7bsWnXG3yFZJIDmUVBGw=";
      };
      dependencies = with final.vimPlugins; [
        nui-nvim
        nvim-dap
        nvim-lspconfig
      ];
    };

    nvim-spring-boot = final.vimUtils.buildVimPlugin {
      name = "spring-boot.nvim";
      src = final.fetchFromGitHub {
        owner = "JavaHello";
        repo = "spring-boot.nvim";
        rev = "98c6ff1dcdda943d341bba3c00ae9d190a2e5f7d";
        hash = "sha256-JkOWlqyVLcwW7hxOGj5jb8BpUge3bUHbSV0o5qOYW1c=";
      };
    };
  };
}
