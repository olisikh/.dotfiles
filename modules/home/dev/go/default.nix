{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.go;
in
{
  options.${namespace}.dev.go = {
    enable = mkBoolOpt false "Enable Go toolchain and common development utilities";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Toolchain, editor support, and debugging
      go
      gopls
      delve

      # Formatting and code generation
      gofumpt
      (lib.lowPrio gotools) # low priority to avoid collision with `stress` package
      gomodifytags
      impl
      gotests
      mockgen

      # Testing, linting, and security
      gotestsum
      golangci-lint
      go-tools
      govulncheck
      gosec

      # Release automation
      goreleaser
    ];
  };
}
