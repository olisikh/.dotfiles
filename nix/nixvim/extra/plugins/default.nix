{ pkgs, lib, ... }:
let
  harpoon-lualine = (pkgs.vimUtils.buildVimPlugin {
    name = "harpoon-lualine";
    src = pkgs.fetchFromGitHub {
      owner = "letieu";
      repo = "harpoon-lualine";
      rev = "master";
      hash = "sha256-pH7U1BYD7B1y611TJ+t8ggPM3KOaSIB3Jtuj3fPKqpc=";
    };
    dependencies = with pkgs.vimPlugins; [ lualine-nvim ];
  });
  nvim-scala-zio-quickfix = (pkgs.vimUtils.buildVimPlugin {
    name = "scala-zio-quickfix";
    src = pkgs.fetchFromGitHub {
      owner = "olisikh";
      repo = "nvim-scala-zio-quickfix";
      rev = "main";
      hash = "sha256-dVRVDBZWncEkBw6cLBJE2HZ8KhNSpffEn3Exvnllx78=";
    };
    # TODO: does plugin need treesitter dependency? it should be part of neovim now
    dependencies = with pkgs.vimPlugins; [
      nvim-treesitter
      nvim-treesitter-parsers.scala
      plenary-nvim
      nvim-metals
      none-ls-nvim
    ];
  });
  nvim-dap-kotlin = (pkgs.vimUtils.buildVimPlugin {
    name = "nvim-dap-kotlin";
    src = pkgs.fetchFromGitHub {
      owner = "olisikh";
      repo = "nvim-dap-kotlin";
      rev = "fix/bugs_and_deprecations";
      hash = "sha256-slmMBcg44Bwo8QIJp467eQt5/lojRsWqoxZxMR5wCLA=";
    };
    dependencies = with pkgs.vimPlugins; [ nvim-dap ];
  });
  neotest-scala = (pkgs.vimUtils.buildVimPlugin {
    name = "neotest-scala";
    src = pkgs.fetchFromGitHub {
      owner = "olisikh";
      repo = "neotest-scala";
      rev = "main";
      hash = "sha256-RFEPtWPVHKehfc6PMF6ya0UaDpFIJDD8bFG8xwXPpsk=";
    };
    dependencies = with pkgs.vimPlugins; [
      plenary-nvim
      nvim-nio
      nvim-treesitter-parsers.xml
      neotest
    ];
  });
  neotest-gradle = (pkgs.vimUtils.buildVimPlugin {
    name = "neotest-gradle";
    src = pkgs.fetchFromGitHub {
      owner = "olisikh";
      repo = "neotest-gradle";
      rev = "fix/no_tests_found";
      hash = "sha256-ZRI5fMGqKK5BaMPU38Dtl8A+XmWBzBI9af6wld/V0Q0=";
    };
    dependencies = with pkgs.vimPlugins; [ plenary-nvim nvim-nio neotest ];
  });
in
with pkgs.vimPlugins; [
  nvim-metals
  nvim-jdtls
  lazydev-nvim
  copilot-lualine
  harpoon2
  treesj
  harpoon-lualine
  nvim-dap-kotlin
  nvim-scala-zio-quickfix
  neotest-gradle
  neotest-scala
]
