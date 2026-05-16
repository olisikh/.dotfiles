{ pkgs, ... }:

pkgs.stdenvNoCC.mkDerivation rec {
  pname = "codexbar-provider-icons-fonts";
  version = "0.0.1";

  src = pkgs.fetchFromGitHub {
    owner = "steipete";
    repo = "CodexBar";
    rev = "a2d532335d2da10114e5fb6e41d4587fc673fabf";
    sha256 = "sha256-ZT1DqM1kIQ2Q9N9buD+y/+HlrpAGS6ysPkL0sPc4/yw=";
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
    install -Dm644 codexbar-provider-icons-fonts.tsv \
      $out/share/codexbar-provider-icons-fonts/glyphs.tsv
    runHook postInstall
  '';
}
