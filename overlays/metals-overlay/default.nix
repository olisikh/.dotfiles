{ ... }:
final: prev:
let
  version = "2.0.0-M18";
  metals-v2 = prev.metals.overrideAttrs (old: {
    inherit version;
    passthru = old.passthru // {
      # HACK: this is an impure override that injects CA certs for corporate TLS proxy into the build command.
      deps = old.passthru.deps.overrideAttrs (depsOld: {
        name = "metals-deps-${version}";
        buildCommand = builtins.replaceStrings [
          "export COURSIER_CACHE=$(pwd)"
          old.version
        ] [
          ''
            export COURSIER_CACHE=$(pwd)
            # The corporate TLS proxy CA is available on work hosts only.
            if [ -r /opt/jdk17/lib/security/cacerts ]; then
              export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=/opt/jdk17/lib/security/cacerts"
            fi
            export COURSIER_REPOSITORIES=https://repo.maven.apache.org/maven2
          ''
          version
        ] depsOld.buildCommand;
        outputHash = "sha256-v93Yy5PfEsS2FUTMHaxV+QKc6OqYR/afgMxXF2rHMp0=";
      });
    };
  });
in
{
  metals = metals-v2.override {
    extraJavaOpts =
      "-XX:+UseG1GC -XX:+UseStringDeduplication -Xss4m -Xms100m \\$METALS_OPTS";
  };
}
