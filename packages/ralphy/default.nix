{ stdenv, fetchFromGitHub, lib }:

stdenv.mkDerivation {
  pname = "ralphy";
  version = "unstable-2026-01-16";

  src = fetchFromGitHub {
    owner = "michaelshimeles";
    repo = "ralphy";
    rev = "b0f0bade9d7eb10279036dbbcedb672e52838b33";
    hash = "sha256-CuFfRv7uQ5sddXkbtpnhnyJRT8iXvqchUZ2MEtHHz4M=";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp ralphy.sh $out/bin/ralphy
    chmod +x $out/bin/ralphy
  '';

  meta = with lib; {
    description = "Autonomous AI coding loop that runs Claude Code, OpenCode, Codex, or Cursor to work through tasks until complete";
    homepage = "https://github.com/michaelshimeles/ralphy";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ ];
  };
}
