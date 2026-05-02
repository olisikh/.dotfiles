{ pkgs, ... }:
let
  buildRaycastExtension = { name, srcHash, npmHash }:
    let
      src = pkgs.fetchFromGitHub
        {
          inherit name;

          owner = "raycast";
          repo = "extensions";
          rev = "adc9a3fd556902021c48e61004b3866d5e24f06e";
          sha256 = srcHash;
          sparseCheckout = [ "/extensions/${name}" ];
        } + "/extensions/${name}";
    in
    pkgs.buildNpmPackage {
      inherit name src;

      npmDepsHash = npmHash;

      buildPhase = ''
        runHook preBuild
        mkdir -p $out
        npm run build -- -o $out
        runHook postBuild
      '';

      installPhase = "true";
    };
in
{
  handy = buildRaycastExtension {
    name = "handy";
    srcHash = "sha256-9g6J23Z+2TMnPcyrBMfFAmRYD89+pOIg0Se3u3o7uGI=";
    npmHash = "sha256-d9nejRK0nQ3OTZdQA+jbyIyQ+32EooW79F517Fhn25Y=";
  };

  brew = buildRaycastExtension {
    name = "brew";
    srcHash = "sha256-7DdKx5V5F7HqtxvEfT7Mn3rKG4ceN1UfEmsN3ne0Gu8=";
    npmHash = "sha256-tb9VwHhWDRHc2Z03JBiuHJApu8KQ6qhgErN9FLlV8eA=";
  };

  github = buildRaycastExtension {
    name = "github";
    srcHash = "sha256-xblJdbFWAqBxW1R1vmDUZgUgrU5FCmEPJCWHD6QlIJw=";
    npmHash = "sha256-sLiHavvRk/HhSLynQbe/F07ahZ2/nXzRm4QaxQGa1PQ=";
  };
}
