{ inputs, ... }:
final: prev:
let
  openclaw-gateway = prev.callPackage "${inputs.nix-openclaw}/nix/packages/openclaw-gateway.nix" {
    sourceInfo = {
      owner = "openclaw";
      repo = "openclaw";

      # Release tag v2026.4.21 currently points at this commit.
      rev = "f788c88b4c508c335336fb292afed8c900656d6d";
      hash = "sha256-K1Pl9lXzGKfoq/fXWxYX5PoY3IBzJr0PPstUDGET/gs=";
      pnpmDepsHash = "sha256-FDajXHs4s0+QDRPq4ZxQWWW9rqeSJVYACAl/5Mw2Agc=";
    };
  };
in
{
  openclawPackages = prev.openclawPackages // {
    inherit openclaw-gateway;
  };
}
