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
        rev = "e1f1b182ce994e3ba5dfa9941cadee79e07c5877";
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
        rev = "b78dcea24fb304d7e2f1058683abc5593719cf5e";
        hash = "sha256-a2P3USCuK+e2cDixJpS4ZKgqEiRuWfmzGOP+oxoRyJo=";
      };
      dependencies = with pkgs.vimPlugins; [ nvim-dap ];
    });
  });
}
