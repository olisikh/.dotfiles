{ pkgs, ... }: {
  "ftplugin/lua.lua".source = ./files/ftplugin/lua.lua;
  "ftplugin/scala.lua".source = ./files/ftplugin/scala.lua;
  "ftplugin/terraform.lua".source = ./files/ftplugin/terraform.lua;

  "ftplugin/java.lua".text = import ./files/ftplugin/java.lua.nix { inherit pkgs; };

  "queries/lua/injections.scm".source = ./files/queries/lua/injections.scm;
  "queries/scala/injections.scm".source = ./files/queries/scala/injections.scm;
}
