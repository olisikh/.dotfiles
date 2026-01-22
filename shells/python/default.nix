{ lib, inputs, namespace, pkgs, mkShell, ... }:
mkShell {
  nativeBuildInputs = [ ];

  buildInputs = with pkgs; [
    (python3.withPackages (ps: with ps; [
      pytest
      debugpy
    ]))
    uv
  ];

  shellHook = ''
    echo "Python dev shell loaded!"
  '';
}

