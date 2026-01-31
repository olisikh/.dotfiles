{ pkgs, ... }:
{
  extraPlugins = with pkgs.vimPlugins; [ nvim-metals ];
}
