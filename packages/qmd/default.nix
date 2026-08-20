{ makeWrapper
, nodejs_24
, runCommand
}:

runCommand "qmd" {
  nativeBuildInputs = [ makeWrapper ];
} ''
  mkdir -p "$out/bin"
  makeWrapper ${nodejs_24}/bin/npx "$out/bin/qmd" \
    --add-flags "--yes @tobilu/qmd@2.8.3"
''
