{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.jvm;

  jdk = pkgs.jdk25;
  scala = pkgs.scala-next;
in
{
  options.${namespace}.dev.jvm = {
    enable = mkBoolOpt false "Enable JVM toolchain (jdk, scala, kotlin, gradle, sbt, metals, bloop)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      jdk
      scala
      (sbt.override { jre = jdk; })
      (metals.override { jre = jdk; })
      (bloop.override { jre = jdk; })
      kotlin
      gradle
    ];

    home.sessionVariables = {
      SCALA_HOME = scala;
      SCALA_CLI_POWER = "true";
      JAVA_HOME = jdk;
    };
  };
}
