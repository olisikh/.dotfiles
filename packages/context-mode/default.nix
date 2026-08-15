{ lib
, buildNpmPackage
, fetchurl
, makeWrapper
, nodejs_24
}:

buildNpmPackage {
  pname = "context-mode";
  version = "1.0.169";

  src = fetchurl {
    url = "https://registry.npmjs.org/context-mode/-/context-mode-1.0.169.tgz";
    hash = "sha512-94JIaFuLjF9SO2BsGTrbGtyT44K95+9OC8BdbaL/UT76xOkanJLfUR5CzmNw+GELXZQqH4nBrKg9wjBnSFkVnQ==";
  };

  # The published npm archive does not include a package-lock.json. Keep a
  # generated lockfile next to this package so npm dependencies remain
  # reproducible inside the Nix build.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';
  npmDepsHash = "sha256-b/8zqCr0QIDMjzErMT5IEx8Ga5JvahMPrMmc5J4J/qA=";
  npmInstallFlags = [ "--omit=dev" ];
  dontNpmBuild = true;
  nodejs = nodejs_24;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib/context-mode"
    install -Dm644 cli.bundle.mjs server.bundle.mjs package.json \
      -t "$out/lib/context-mode"
    cp -r node_modules "$out/lib/context-mode/"

    makeWrapper ${lib.getExe nodejs_24} "$out/bin/context-mode" \
      --add-flags "$out/lib/context-mode/cli.bundle.mjs"

    runHook postInstall
  '';

  meta = with lib; {
    description = "MCP server and context optimization tool for AI coding agents";
    homepage = "https://github.com/mksglu/context-mode";
    license = licenses.elastic20;
    platforms = platforms.unix;
    mainProgram = "context-mode";
  };
}
