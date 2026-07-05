{ pkgs, ... }:
{
  extraPlugins = [ pkgs.vimPlugins.smart-paste ];

  extraConfigLua = ''
    require("smart-paste").setup()
  '';
}
