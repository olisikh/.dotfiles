{ lib
, stdenvNoCC
, fetchurl
, makeWrapper
}:

stdenvNoCC.mkDerivation rec {
  pname = "voicebox";
  version = "0.5.0";

  src = fetchurl {
    url = "https://github.com/jamiepine/voicebox/releases/latest/download/Voicebox_aarch64.app.tar.gz";
    hash = "sha256-ifjh4qd2gxAsQNQ5Vi3BRGOqnYfPLfWo1RUw5kWb6gk=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R Voicebox.app "$out/Applications/Voicebox.app"

    mkdir -p "$out/bin"

    makeWrapper "$out/Applications/Voicebox.app/Contents/MacOS/voicebox-server" "$out/bin/voicebox-server" \
      --set-default VOICEBOX_BACKEND_VARIANT cpu

    makeWrapper "$out/Applications/Voicebox.app/Contents/MacOS/voicebox-mcp" "$out/bin/voicebox-mcp"

    runHook postInstall
  '';

  meta = {
    description = "Local-first AI voice studio (Voicebox server + MCP shim)";
    homepage = "https://voicebox.sh";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "aarch64-darwin" ];
    mainProgram = "voicebox-server";
  };
}
