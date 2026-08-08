{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "macmon";
  version = "unstable-2026-07-06";

  src = fetchFromGitHub {
    owner = "vladkens";
    repo = "macmon";
    rev = "6919d7781b6c55a6e3bedff83a210435837e1dfe";
    hash = "sha256-tdWuxpV+AAN189etks6LVo4OYDYQNd9dzfopECFgoR8=";
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
