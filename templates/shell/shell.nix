{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  # NOTE: all attributes of stdenv.mkDerivation are available here

  # build dependencies
  nativeBuildInputs = [ ];

  # runtime dependencies
  buildInputs = [ ];

  # add executable packages to the nix-shell environment.
  packages = [ pkgs.gnumake ];

  # build dependencies of the listed derivations to the nix-shell environment
  inputsFrom = [ pkgs.hello ];

  # commands to run when the shell starts
  shellHook = ''
    export NIX_SHELL=1
  '';
}
