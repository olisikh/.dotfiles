{ ... }:
final: prev: {
  metals = prev.metals.override {
    extraJavaOpts =
      "-XX:+UseG1GC -XX:+UseStringDeduplication -Xss4m -Xms100m \\$METALS_OPTS";
  };
}
