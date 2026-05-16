{ pkgs, ... }:

pkgs.stdenvNoCC.mkDerivation rec {
  pname = "codexbar-provider-icons-fonts";
  version = "0.24";

  src = pkgs.fetchFromGitHub {
    owner = "steipete";
    repo = "CodexBar";
    rev = "a2d53233";
    sha256 = "0b7z73vv1x227snaqjq6j2pfbqgzn8zvhnyzyj80s8b4rnl46gb5";
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
