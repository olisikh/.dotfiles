{ channels, inputs, ... }:

final: prev: {
  olisikh = (prev.olisikh or {}) // {
    "raycast-plugins" = final.callPackage ../../packages/raycast-plugins/default.nix {};
  };
}
