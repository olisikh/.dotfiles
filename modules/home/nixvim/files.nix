{ pkgs, ... }:
{

  extraFiles = {
    "ftplugin/terraform.lua".source = ./ftplugin/terraform.lua;

    "queries/lua/injections.scm".source = ./queries/lua/injections.scm;
    "queries/scala/injections.scm".source = ./queries/scala/injections.scm;

    # custom snippets
    "snippets".source = ./snippets;
  };
}
