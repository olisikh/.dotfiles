{ ... }:
{

  extraFiles = {
    "checkstyle.xml".source = ./checkstyle.xml;
    "jdtls/org.eclipse.jdt.core.prefs".source = ./jdtls/org.eclipse.jdt.core.prefs;
    "jdtls/formatter.xml".source = ./jdtls/formatter.xml;

    "ftplugin/terraform.lua".source = ./ftplugin/terraform.lua;
    "ftplugin/kotlin.lua".source = ./ftplugin/kotlin.lua;
    "ftplugin/graphql.lua".source = ./ftplugin/graphql.lua;
    "ftplugin/java.lua".source = ./ftplugin/java.lua;
    "ftplugin/bru.lua".source = ./ftplugin/bru.lua;

    "queries/lua/injections.scm".source = ./queries/lua/injections.scm;
    "queries/scala/injections.scm".source = ./queries/scala/injections.scm;
    "queries/bruno/highlights.scm".source = ./queries/bruno/highlights.scm;
    "queries/bruno/locals.scm".source = ./queries/bruno/locals.scm;
    "queries/bruno/textobjects.scm".source = ./queries/bruno/textobjects.scm;

    # custom snippets
    "snippets".source = ./snippets;
  };
}
