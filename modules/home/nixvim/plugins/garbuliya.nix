{ pkgs, ... }:
let
  name = "garbuliya";
  garbuliya = pkgs.vimUtils.buildVimPlugin {
    inherit name;
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
