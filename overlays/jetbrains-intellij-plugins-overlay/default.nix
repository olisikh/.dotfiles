{ ... }:
# NOTE: fixed intellij build, otherwise it complains it is not allowed to use some files for build
# remove it once it's no longer needed or when you figured out what is the actual problem
final: prev: {
  jetbrains = prev.jetbrains // {
    plugins = prev.jetbrains.plugins // {
      addPlugins = ide: ps:
        (prev.jetbrains.plugins.addPlugins ide ps).overrideAttrs (_: {
          disallowedReferences = [ ];
          allowedReferences = null;
        });
    };
  };
}
