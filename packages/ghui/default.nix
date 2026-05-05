{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchNpmDeps,
  bun,
  gh,
  git,
  nodejs,
  runtimeShell,
  versionCheckHook,
}:

buildNpmPackage (finalAttrs: {
  pname = "ghui";
  version = "0.6.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "kitlangton";
    repo = "ghui";
    rev = "e9ac64c548af1c3a9ef434184fba222b40ff9d62";
    hash = "sha256-WrhpSA29vcX6K101E2TiBPkEq72ZuBDFEImFGUMjE5c=";
  };

  npmDeps = fetchNpmDeps {
    name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
    inherit (finalAttrs) src;
    fetcherVersion = finalAttrs.npmDepsFetcherVersion;
    hash = lib.fakeHash;
    nativeBuildInputs = [ nodejs ];
    prePatch = ''
      export HOME=$TMPDIR
      npm pkg set 'dependencies.@ghui/keymap=file:packages/keymap'
      npm pkg delete 'devDependencies.@ghui/keymap'
      npm install --package-lock-only --ignore-scripts --no-audit --no-fund
    '';
  };

  prePatch = ''
    export HOME=$TMPDIR
    export npmDeps
    npm pkg set 'dependencies.@ghui/keymap=file:packages/keymap'
    npm pkg delete 'devDependencies.@ghui/keymap'
    cp ${finalAttrs.npmDeps}/package-lock.json package-lock.json
  '';

  nativeBuildInputs = [ bun ];

  npmDepsFetcherVersion = 3;

  npmFlags = [
    "--no-audit"
    "--no-fund"
  ];

  npmBuildScript = "build:cli";

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  postInstallCheck = ''
    cd $out/lib/ghui
    ${lib.getExe bun} -e '
      await import("@effect/atom-react")
      await import("@ghui/keymap")
      await import("@opentui/core")
      await import("@opentui/react")
      await import("effect")
      await import("react")
      await import("scheduler")
    '
  '';

  installPhase = ''
    runHook preInstall

    npm prune --omit=dev --no-save --no-audit --no-fund

    mkdir -p $out/lib/ghui $out/bin
    cp -r dist node_modules packages package.json README.md LICENSE .env.example $out/lib/ghui/
    rm -f $out/lib/ghui/node_modules/.bin/ghui

    cat > $out/bin/ghui <<'EOF'
    #!@runtimeShell@
    case "''${1-}" in
      -v|--version|version)
        echo @version@
        exit 0
        ;;
      -h|--help|help)
        printf '%s\n' \
          "ghui @version@" \
          "" \
          "Terminal UI for GitHub pull requests." \
          "" \
          "Usage:" \
          "  ghui              Start the TUI" \
          "  ghui -v, --version" \
          "                    Print the installed version" \
          "  ghui -h, --help   Show this help message"
        exit 0
        ;;
    esac

    export PATH=@path@:$PATH
    exec @bun@ "@out@/lib/ghui/dist/index.js" "$@"
    EOF
    substituteInPlace $out/bin/ghui \
      --replace-fail @runtimeShell@ ${runtimeShell} \
      --replace-fail @version@ ${finalAttrs.version} \
      --replace-fail @path@ ${lib.makeBinPath [ gh git ]} \
      --replace-fail @bun@ ${lib.getExe bun} \
      --replace-fail @out@ $out
    chmod +x $out/bin/ghui

    runHook postInstall
  '';

  meta = {
    description = "Terminal UI for GitHub pull requests";
    homepage = "https://github.com/kitlangton/ghui";
    changelog = "https://github.com/kitlangton/ghui/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "ghui";
    platforms = bun.meta.platforms;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
