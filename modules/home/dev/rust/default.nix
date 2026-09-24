{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.rust;
in
{
  options.${namespace}.dev.rust = {
    enable = mkBoolOpt false "Enable Rust toolchain and common development utilities";
  };

  config = mkIf cfg.enable {
    home = {

      packages = with pkgs; [
        # Toolchain and editor support
        rustc
        cargo
        rustfmt
        clippy
        rust-analyzer

        # Dependency and workflow helpers
        cargo-edit
        cargo-watch
        cargo-expand
        cargo-outdated
        sccache

        # Testing, coverage, and supply-chain checks
        cargo-nextest
        cargo-llvm-cov
        cargo-audit
        cargo-deny

        # Common native build helpers; project-specific libraries stay in shell.nix.
        pkg-config
        cmake
      ];

      sessionVariables = {
        RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
      };
    };
  };
}
