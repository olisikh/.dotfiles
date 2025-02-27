{ pkgs, ... }: {
  "ftplugin/lua.lua".source = ./ftplugin/lua.lua;
  "ftplugin/scala.lua".source = ./ftplugin/scala.lua;
  "ftplugin/terraform.lua".source = ./ftplugin/terraform.lua;

  "ftplugin/java.lua".text = import ./ftplugin/java.lua.nix { inherit pkgs; };

  "queries/lua/injections.scm".source = ./queries/lua/injections.scm;
  "queries/scala/injections.scm".source = ./queries/scala/injections.scm;
}
