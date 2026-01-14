{ channels, inputs, ... }:

final: prev:
let 
  pkgs = prev.pkgs;
in
{
  vimPlugins = prev.vimPlugins.extend (self: super: {

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
  });
}
