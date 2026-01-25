{ pkgs, ... }:
let
  name = "garbuliya";
  garbuliya = pkgs.vimUtils.buildVimPlugin {
    inherit name;
    src = pkgs.runCommand "garbuliya-src" { } ''
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

    vim.keymap.set( { "n", "v" }, "<leader>oi", ":Garbuliya implement<cr>", { desc = "garbuliya: implement at cursor" })
    vim.keymap.set( { "n", "v" }, "<leader>oC", ":Garbuliya cancel<cr>", { desc = "garbuliya: cancel all" })
  '';
}
