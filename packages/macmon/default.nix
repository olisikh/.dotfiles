{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "macmon";
  version = "unstable-2026-07-06";

  src = fetchFromGitHub {
    owner = "vladkens";
    repo = "macmon";
    rev = "337350e18a46e41a060c6c3f9d75793568e16873";
    hash = "sha256-BLKV3ZGf+b5sLg00YVDNmNCqTr5S+psX0htFXfZER+Y=";
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
