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
    enable = mkBoolOpt false "Enable JVM toolchain (jdk, scala, kotlin, gradle, sbt, metals, bloop, maven)";
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
      maven
    ];

    home.sessionVariables = {
      JAVA_HOME = jdk;
      SCALA_HOME = scala;
      SCALA_CLI_POWER = "true";
      KOTLIN_HOME = pkgs.kotlin;
      M2_HOME = pkgs.maven;
      GRADLE_HOME = pkgs.gradle;
    };
  };
}
