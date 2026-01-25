{ pkgs, ... }:
let
  name = "garbuliya";
  garbuliya = pkgs.vimUtils.buildVimPlugin {
    inherit name;
    src = pkgs.runCommand "garbuliya-src" {} ''
      mkdir -p $out/lua/garbuliya
      cp ${./garbuliya}/*.lua $out/lua/garbuliya/
    '';
  };
in
{
  extraPlugins = [
    garbuliya
  ];

  extraConfigLua = ''
    require("garbuliya").setup({})

    vim.keymap.set( { "n", "v" }, "<leader>gi", ":GarbuliyaImplement<cr>", { desc = "garbuliya: implement at cursor" })
  '';
}
