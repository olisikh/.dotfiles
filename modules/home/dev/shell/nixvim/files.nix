{ ... }:
{

  extraFiles = {
    "ftplugin/terraform.lua".source = ./ftplugin/terraform.lua;
    "ftplugin/kotlin.lua".source = ./ftplugin/kotlin.lua;
    "ftplugin/graphql.lua".source = ./ftplugin/graphql.lua;

    "queries/lua/injections.scm".source = ./queries/lua/injections.scm;
    "queries/scala/injections.scm".source = ./queries/scala/injections.scm;

    # custom snippets
    "snippets".source = ./snippets;
  };
}
