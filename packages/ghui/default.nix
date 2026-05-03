{ lib
, buildNpmPackage
, fetchFromGitHub
, fetchNpmDeps
, makeWrapper
, nodejs
, bun
, gh
, git
, ...
}:

buildNpmPackage (finalAttrs: {
  pname = "ghui";
  version = "0.3.3";

  src = fetchFromGitHub {
    owner = "kitlangton";
    repo = "ghui";
    rev = "dea1d03a592904279b149aa1bfe0daa7778d0402";
    hash = "sha256-pcKVNA3k8UZm7Nk7QLzYphiTtE3tXLgD/qcJbX/1vdY=";
  };

  nativeBuildInputs = [
    bun
    makeWrapper
  ];

  npmDeps = fetchNpmDeps {
    name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
    inherit (finalAttrs) src;
    hash = "sha256-kVXEz7g7Sad2D1byCXX1GsAyva7hZ+FFB5ziAYZbmQQ=";
    nativeBuildInputs = [ nodejs ];
    prePatch = ''
      npm install --package-lock-only --ignore-scripts
    '';
  };

  prePatch = ''
    cp ${finalAttrs.npmDeps}/package-lock.json package-lock.json
  '';

  npmBuildScript = "build:cli";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/ghui $out/bin
    cp -r bin dist node_modules package.json packages README.md LICENSE .env.example $out/lib/ghui/

    makeWrapper ${lib.getExe bun} $out/bin/ghui \
      --add-flags "$out/lib/ghui/bin/ghui.js" \
      --prefix PATH : ${lib.makeBinPath [ gh git ]}

    runHook postInstall
  '';

  meta = {
    description = "Terminal UI for GitHub pull requests";
    homepage = "https://github.com/kitlangton/ghui";
    license = lib.licenses.mit;
    mainProgram = "ghui";
  };
})
