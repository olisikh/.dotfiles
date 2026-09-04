{ ... }:
final: prev: {
  vimPlugins = prev.vimPlugins // {
    nvim-treesitter-parsers = prev.vimPlugins.nvim-treesitter-parsers // {
      bruno = final.neovimUtils.grammarToPlugin (
        final.tree-sitter.buildGrammar {
          language = "bruno";
          version = "0.0.0+rev=c6d42e3";
          src = final.fetchFromGitHub {
            owner = "kristoferssolo";
            repo = "tree-sitter-bruno";
            rev = "c6d42e349353f02ad051dd9c88a38df639ef688f";
            hash = "sha256-7XWWAT0PB29TllAo0HWAgGmdflmmtyFscl6XSA12tpU=";
          };
          generate = false;
        }
      );
    };

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
        rev = "75383a1320fe3593e67fcb18a225146751f8fef9";
        hash = "sha256-xBzrJHcR3q+Zso0byNK8q4ql8mWGleZy9R+dK0fev14=";
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
        rev = "eea95b752bceb6ca410b3e2d87a1a02d08bd61a6";
        hash = "sha256-GYer7azYjYWGMTzNDLxHshGYJCl+2zi2+78LjHsuaUc=";
      };
    };

    nvim-dap-ui = final.vimUtils.buildVimPlugin {
      name = "nvim-dap-ui";
      src = final.fetchFromGitHub {
        owner = "rcarriga";
        repo = "nvim-dap-ui";
        rev = "cc9dd33aade7f20bae414d0cba163bc60d4d4b43";
        hash = "sha256-za3/6W1J6aMvNZQq8ANCq+TGHKHJtSxR/C5t3/oL3DI=";
      };
      dependencies = with final.vimPlugins; [ nvim-dap nvim-nio ];
      doCheck = false;
    };


    # HACK: prevent SSL errors as nix fails to fetch these plugins from codeberg.org git repos.
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
        rev = "c9a0738e45f1bd41d792a126941348dce661cf9b";
        hash = "sha256-VVHXHBKGmDnltHBMcVoBElaKMElXwJwB/7IZROQGCpg=";
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
        rev = "3d55c8f67c6ae5c15e1042571e107c7a3d5c5f4e";
        hash = "sha256-IcV2QgxhGpTs7xTzLMOrqGuFdAaSuC96HQ3cu8+fTFY=";
      };
      doCheck = false;
    };

    faaah = final.vimUtils.buildVimPlugin {
      name = "faaah";
      src = final.fetchFromGitHub {
        owner = "olisikh";
        repo = "faaah.nvim";
        rev = "afa78149a46e798c4cf072583a3acb48cd45c973";
        hash = "sha256-Ht6LRPb5Dngahe2hnXxCLAueFvoNSuEgH0rhbWbKtxc=";
      };
    };

    smart-paste = final.vimUtils.buildVimPlugin {
      name = "smart-paste";
      src = final.fetchFromGitHub {
        owner = "nemanjamalesija";
        repo = "smart-paste.nvim";
        rev = "a81e5511adc6fc145a7a71b08819440fd059af34";
        hash = "sha256-t8wt46sOcBdRcjpA4ii0EaycLAg3aLDdHapNJvSMyxM=";
      };
    };

    simple-zoom = final.vimUtils.buildVimPlugin {
      name = "simple-zoom.nvim";
      src = final.fetchFromGitHub {
        owner = "fasterius";
        repo = "simple-zoom.nvim";
        rev = "acead628aa1ce6c2fc4c77bd48d651ce12b8ab85";
        hash = "sha256-gFI6+65eLNruIpowQustiz71Y/q3GhUXudFxZEp+bLs=";
      };
    };
  };
}
