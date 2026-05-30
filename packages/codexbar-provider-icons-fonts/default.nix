{ pkgs, ... }:

pkgs.stdenvNoCC.mkDerivation rec {
  pname = "codexbar-provider-icons-fonts";
  version = "0.0.1";

  src = pkgs.fetchFromGitHub {
    owner = "steipete";
    repo = "CodexBar";
    rev = "d2d1fc32011a22a12e70c1e259bbace9cff84dcd";
    hash = "sha256-LnIHqESnRjFmyDzDanXZu2d73KI1x+brUeM4bm8qGu0=";
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
