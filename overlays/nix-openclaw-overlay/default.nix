{ inputs, ... }:
final: prev:
let
  openclaw-gateway = prev.callPackage "${inputs.nix-openclaw}/nix/packages/openclaw-gateway.nix" {
    sourceInfo = {
      owner = "openclaw";
      repo = "openclaw";

      # Release tag v2026.4.23 currently points at this commit.
      rev = "a9797214338ba31c52c796adbb75afb16e0684a9";
      hash = "sha256-Mym3yAyOqr3g8oFEt6yBzMbSkyUOkm0ym/IRD2QfcBY=";
      pnpmDepsHash = "sha256-xwLxNnr4PkQqWa2gJaGmWapKuO7qwSkTpIM6LwIbjLc=";
    };
  };
in
{
  openclawPackages = prev.openclawPackages // {
    inherit openclaw-gateway;
  };
}
