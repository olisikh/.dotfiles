{ pkgs, ... }:

pkgs.stdenvNoCC.mkDerivation rec {
  pname = "codexbar-provider-icons-fonts";
  version = "0.0.1";

  src = pkgs.fetchFromGitHub {
    owner = "steipete";
    repo = "CodexBar";
    rev = "702af5a4f48c10f7c06d6b6399f97d55cb44da92";
    hash = "sha256-PqMCxGFI86AbPfY4nGHILor0EOtm/qbupgjyG7UpFzs=";
  };

  nativeBuildInputs = [ pkgs.fontforge ];

  buildPhase = ''
    runHook preBuild
    fontforge -lang=py -script ${./generate.py} \
      Sources/CodexBar/Resources \
      codexbar-provider-icons-fonts
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 codexbar-provider-icons-fonts.ttf \
      $out/share/fonts/truetype/CodexBarProviderIcons.ttf
    install -Dm755 codexbar-provider-icons-fonts.sh \
      $out/bin/icon_map.sh
    runHook postInstall
  '';
}
