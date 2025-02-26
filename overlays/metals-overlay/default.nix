{ channels, namespace, inputs, ... }:

final: prev: {
  metals = prev.metals.overrideAttrs (oldAttrs: {
    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${prev.jre}/bin/java $out/bin/metals \
      --add-flags "${oldAttrs.extraJavaOpts} \$METALS_OPTS -cp $CLASSPATH scala.meta.metals.Main"
    '';
  });
}

