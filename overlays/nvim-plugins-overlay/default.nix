{ ... }:
final: prev: {
  vimPlugins = prev.vimPlugins // {
    "99" = final.vimUtils.buildVimPlugin {
      name = "99";
      src = final.fetchFromGitHub {
        owner = "theprimeagen";
        repo = "99";
        rev = "c17422457027c913c76c75a921fca1e623d2678e";
        hash = "sha256-iilpiG81kHIv7Y0qvPzZOanNA0lsPotlB18cvtmTy0o=";
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
        rev = "e5a76f39a02c9dfab24ae9b11a158e36c6284f0a";
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
        owner = "nvim-java";
        repo = "nvim-java";
        rev = "9e8b842ea9eff3ebf25fb7360908ed4d4f87c56a";
        hash = "sha256-IPeuAlXiBZhAHlac/e/2oPpSnptovZ7kxIuzF+AAeQs=";
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

    nvim-dap-ui = final.vimUtils.buildVimPlugin {
      name = "nvim-dap-ui";
      src = final.fetchFromGitHub {
        owner = "rcarriga";
        repo = "nvim-dap-ui";
        rev = "1a66cabaa4a4da0be107d5eda6d57242f0fe7e49";
        hash = "sha256-J/gUD4X//JtC2HB3HBeONivCQdMnXDnZJWd6jFF9+nk=";
      };
      dependencies = with final.vimPlugins; [ nvim-dap nvim-nio ];
      doCheck = false;
    };


    # HACK: prevert SSL errors as nix fails to fetch these plugins from codeberg.org git repos.
    nvim-dap-virtual-text = final.vimUtils.buildVimPlugin {
      name = "nvim-dap-virtual-text";
      src = final.fetchFromGitHub {
        owner = "theHamsta";
        repo = "nvim-dap-virtual-text";
        rev = "fbdb48c2ed45f4a8293d0d483f7730d24467ccb6";
        hash = "sha256-8hsk+EwnvoHCNhb0dcL9e4hQg9I+t/5Cy9ZoZgcz4fU=";
      };
      dependencies = with final.vimPlugins; [ nvim-dap nvim-treesitter ];
      doCheck = false;
    };

    nvim-dap = final.vimUtils.buildVimPlugin {
      name = "nvim-dap";
      src = final.fetchFromGitHub {
        owner = "mfussenegger";
        repo = "nvim-dap";
        rev = "9e848e09a697ee95302a3ef2dd43fd6eb709e570";
        hash = "sha256-IHm3CwO7qUTtOZqhljDjSzz4WbaAJ4kPY384MyZZ9ac=";
      };
      doCheck = false;
    };

    nvim-dap-python = final.vimUtils.buildVimPlugin {
      name = "nvim-dap-python";
      src = final.fetchFromGitHub {
        owner = "mfussenegger";
        repo = "nvim-dap-python";
        rev = "1808458eba2b18f178f990e01376941a42c7f93b";
        hash = "sha256-qqPoYmMPjK74Nyyl7TfsHnJCsIvOYFuQnKWn3Rh8FLU=";
      };
      doCheck = false;
    };

    nvim-lint = final.vimUtils.buildVimPlugin {
      name = "nvim-lint";
      src = final.fetchFromGitHub {
        owner = "mfussenegger";
        repo = "nvim-lint";
        rev = "a219b2c9e5b4765e5c845aba119dad55806fcaf1";
        hash = "sha256-pABhzTRkcxAT/ELeltz47eCAKCnzdoCtc2QRu3wm0xU=";
      };
      doCheck = false;
    };

    faaah = final.vimUtils.buildVimPlugin {
      name = "faaah";
      src = final.fetchFromGitHub {
        owner = "olisikh";
        repo = "faaah.nvim";
        rev = "2baf9183f8c5095faeeb81c34c8d1fedc7a4ab61";
        hash = "sha256-cbbVNWMXIn7UxXBrR4sM/zbmAftf3AVWAcgq44uWibM=";
      };
    };

    smart-paste = final.vimUtils.buildVimPlugin {
      name = "smart-paste";
      src = final.fetchFromGitHub {
        owner = "nemanjamalesija";
        repo = "smart-paste.nvim";
        rev = "24da69b42ba7bbfd93dd6dc314c79223cc34c389";
        hash = "sha256-hM7wPqzuJXYRHd5oGVCMUWloWNsO6ZHKMeB0Da6sBBY=";
      };
    };

  };
}
