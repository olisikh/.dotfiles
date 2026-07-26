{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "macmon";
  version = "unstable-2026-07-06";

  src = fetchFromGitHub {
    owner = "vladkens";
    repo = "macmon";
    rev = "51c94433bc537ba9400b8c7cf4dd15dac6675eb9";
    hash = "sha256-9UD/PXmMln5RiUQXjp2GV3m1R2IQ5ItvoOfpkqGNg/I=";
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
