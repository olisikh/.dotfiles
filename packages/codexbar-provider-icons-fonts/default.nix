{ pkgs, ... }:

pkgs.stdenvNoCC.mkDerivation rec {
  pname = "codexbar-provider-icons-fonts";
  version = "0.0.1";

  src = pkgs.fetchFromGitHub {
    owner = "steipete";
    repo = "CodexBar";
    rev = "e437044c32ba1bae3d64b9884522bdcd76fff916";
    hash = "sha256-3JQAnl9anq2ykoaGhQNeoudupv4HD2PxG3NLizjRIqk=";
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
