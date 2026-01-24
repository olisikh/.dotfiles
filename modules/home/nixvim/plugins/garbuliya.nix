{ pkgs, ... }:

let
  garbuliya = pkgs.vimUtils.buildVimPlugin {
    name = "garbuliya";
    src = pkgs.writeTextDir "lua/garbuliya.lua" (builtins.readFile ./garbuliya/init.lua);
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
