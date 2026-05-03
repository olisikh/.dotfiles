{ lib
, stdenvNoCC
, fetchFromGitHub
, makeWrapper
, bun
, gh
, git

, ...
}:

let
  repo = "ghui";
  version = "0.4.6";
  bunTarget = {
    aarch64-darwin = "bun-darwin-arm64";
    x86_64-darwin = "bun-darwin-x64";
    aarch64-linux = "bun-linux-arm64";
    x86_64-linux = "bun-linux-x64";
  }.${stdenvNoCC.hostPlatform.system} or (throw "Unsupported ghui platform: ${stdenvNoCC.hostPlatform.system}");

  src = fetchFromGitHub {
    owner = "kitlangton";
    repo = repo;
    rev = "ccce54a27712bf0418c91df31ccc6534e4c1dd38";
    hash = "sha256-jMi2Pc2VTpj0cZ2zXqtunG0FxcglCNEt9WzWnwxq+Js=";
  };

  bunDeps = stdenvNoCC.mkDerivation {
    inherit version src;
    pname = repo;
    name = "${repo}-${version}-bun-deps";

    nativeBuildInputs = [ bun ];

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR
      bun install --frozen-lockfile --ignore-scripts --cache-dir $TMPDIR/bun-cache

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -R node_modules $out/node_modules
      cp -R packages $out/packages

      runHook postInstall
    '';

    outputHashMode = "recursive";
    outputHash = "sha256-OdHl09qiNOpjA3x4JLDi7+LGlWn5VuizdUc/ynizCq0=";
  };
in
stdenvNoCC.mkDerivation {
  inherit version src;

  pname = repo;

  nativeBuildInputs = [
    bun
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    cp -R ${bunDeps}/node_modules node_modules
    chmod -R u+w node_modules
    bun build --compile --bytecode --format=esm --target=${bunTarget} --outfile=dist/ghui src/standalone.ts

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/ghui $out/bin
    install -m755 dist/ghui $out/lib/ghui/ghui

    makeWrapper $out/lib/ghui/ghui $out/bin/ghui \
      --prefix PATH : ${lib.makeBinPath [ gh git ]}

    runHook postInstall
  '';

  meta = {
    description = "Terminal UI for GitHub pull requests";
    homepage = "https://github.com/kitlangton/ghui";
    license = lib.licenses.mit;
    mainProgram = "ghui";
  };
}
