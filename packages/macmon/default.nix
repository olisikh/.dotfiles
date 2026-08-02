{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "macmon";
  version = "unstable-2026-07-06";

  src = fetchFromGitHub {
    owner = "vladkens";
    repo = "macmon";
    rev = "417828dc2b4cd055826b83f8d20bb40d224bb322";
    hash = "sha256-eo3sVgCDXwdz8UzubiHSsdESwGaGpolm5Fi1BCB1Bbs=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  meta = with lib; {
    description = "Real-time system monitor for Apple Silicon Macs";
    homepage = "https://github.com/vladkens/macmon";
    license = licenses.mit;
    platforms = platforms.darwin;
    mainProgram = "macmon";
  };
}
