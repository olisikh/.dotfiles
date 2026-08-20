{ makeWrapper
, nodejs_24
, runCommand
}:

runCommand "qmd" {
  nativeBuildInputs = [ makeWrapper ];
} ''
  mkdir -p "$out/bin"
  makeWrapper ${nodejs_24}/bin/npx "$out/bin/qmd" \
    --run 'export NPM_CONFIG_CACHE="''${NPM_CONFIG_CACHE:-$HOME/.cache/qmd/npm}"' \
    --add-flags "--yes --package=@tobilu/qmd@2.8.3 qmd"
''
