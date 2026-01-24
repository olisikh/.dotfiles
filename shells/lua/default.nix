{ lib, inputs, namespace, pkgs, mkShell, ... }:
mkShell {
  nativeBuildInputs = [ ];

  buildInputs = with pkgs; [ lua luarocks-nix ];

  shellHook = ''
    echo "Lua dev shell loaded!"
  '';
}

