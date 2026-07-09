{ lib
, stdenv
, fetchurl
, python3
, jdk
, makeWrapper
}:

let
  version = "1.60.0";
  timestamp = "202606262232";

  # The application ships with different config directories for each platform.
  configDir = if stdenv.hostPlatform.isDarwin then
    (if stdenv.hostPlatform.isAarch64 then "config_mac_arm" else "config_mac")
  else
    (if stdenv.hostPlatform.isAarch64 then "config_linux_arm" else "config_linux");
in
stdenv.mkDerivation rec {
  pname = "jdt-language-server";
  inherit version;

  src = fetchurl {
    url = "https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz";
    hash = "sha256-KgpGNAZ0rk60LaRHHx+uYnlVh7C5TEzK2b44TwwvE6U=";
  };

  sourceRoot = ".";

  buildInputs = [ python3 ];

  installPhase = ''
    runHook preInstall

    install -Dm444 -t $out/share/java/jdtls/plugins/ plugins/*
    install -Dm444 -t $out/share/java/jdtls/features/ features/*
    install -Dm444 -t $out/share/java/jdtls/${configDir} ${configDir}/*

    install -Dm555 -t $out/bin bin/jdtls
    install -Dm444 -t $out/bin bin/jdtls.py

    substituteInPlace $out/bin/jdtls.py \
      --replace-fail "jdtls_base_path = Path(__file__).parent.parent" "jdtls_base_path = Path(\"$out/share/java/jdtls/\")" \
      --replace-fail "java_executable = get_java_executable(known_args)" "java_executable = '${lib.getExe jdk}'"

    substituteInPlace $out/bin/jdtls \
      --replace-fail "#!/usr/bin/env python3" "#!${lib.getExe python3}"

    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/eclipse/eclipse.jdt.ls";
    description = "Java language server (Eclipse JDT LS snapshot)";
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    license = lib.licenses.epl20;
    platforms = lib.platforms.all;
    mainProgram = "jdtls";
  };
}
