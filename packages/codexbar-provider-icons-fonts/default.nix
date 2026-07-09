{ pkgs, ... }:

pkgs.stdenvNoCC.mkDerivation rec {
  pname = "codexbar-provider-icons-fonts";
  version = "0.0.1";

  src = pkgs.fetchFromGitHub {
    owner = "steipete";
    repo = "CodexBar";
    rev = "3b039d15e125f8e978e2c8c8506feff210eb4c6a";
    hash = "sha256-5x3vAztdyfoyE/QnYVZJmU2xHKBCQ5YmkJ9fjC9kXas=";
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
