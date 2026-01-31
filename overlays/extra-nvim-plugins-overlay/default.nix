{ channels, inputs, ... }:

final: prev:
let
  pkgs = prev.pkgs;
in
{
  vimPlugins = prev.vimPlugins.extend (self: super: {
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
