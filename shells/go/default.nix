{ lib, inputs, namespace, pkgs, mkShell, ... }:
mkShell {
  nativeBuildInputs = [ ];

  buildInputs = with pkgs; [ go gofumpt gotools ];

  shellHook = ''
    echo "Go dev shell loaded!"
  '';
}

