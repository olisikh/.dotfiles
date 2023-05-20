{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [ zsh starship ];
}
