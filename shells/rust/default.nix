{ lib, inputs, namespace, pkgs, mkShell, ... }:
mkShell {
  nativeBuildInputs = with pkgs; [ pkg-config ];

  buildInputs = with pkgs; [ cargo rustc rustfmt clippy rust-analyzer glib ];

  env.RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

  shellHook = ''
    echo "Rust dev shell loaded!"
  '';
}
