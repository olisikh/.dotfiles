{ lib
, stdenvNoCC
, fetchFromGitHub
, fetchurl
, makeWrapper
, nodejs
, typescript
}:

let
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "DaviTostes";
    repo = "bruno-language-server";
    rev = "236cbe5092aa63d025049caf6b0aaad84d7bc06a";
    hash = "sha256-IFvlSXjxL1pC+iFHHrpAsMX3FSaXsvkOaXflJ12aIHA=";
  };

  npmSources = [
    {
      path = "node_modules/@types/node";
      src = fetchurl {
        url = "https://registry.npmjs.org/@types/node/-/node-20.19.43.tgz";
        hash = "sha256-mWPyy5bSsm2/nPhiYsaYgVy+yVA69zx851IJ0dBljz0=";
      };
    }
    {
      path = "node_modules/undici-types";
      src = fetchurl {
        url = "https://registry.npmjs.org/undici-types/-/undici-types-6.21.0.tgz";
        hash = "sha256-z6GppeGJiIUOVI9Pa2KcWNoy3DK+uxFuWOowHlFv0W0=";
      };
    }
    {
      path = "node_modules/vscode-jsonrpc";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-jsonrpc/-/vscode-jsonrpc-8.2.0.tgz";
        hash = "sha256-PaRFMcOY8VRQdMtyjjWagi81ufiscXHIR/QvByi5x8s=";
      };
    }
    {
      path = "node_modules/vscode-languageserver";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-languageserver/-/vscode-languageserver-9.0.1.tgz";
        hash = "sha256-bNf0Y654cuWIpN1e1RSUdf4y5TUXUJqB5xXrBUBgJBI=";
      };
    }
    {
      path = "node_modules/vscode-languageserver-protocol";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-languageserver-protocol/-/vscode-languageserver-protocol-3.17.5.tgz";
        hash = "sha256-dHPrLSFj8/i+oJZE+dgDeJoZXllrZdOUbEFX5YPjzMg=";
      };
    }
    {
      path = "node_modules/vscode-languageserver-textdocument";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-languageserver-textdocument/-/vscode-languageserver-textdocument-1.0.12.tgz";
        hash = "sha256-nx0ogU1u6BJn9S9byMkgu2oKI+tt5IlgNFoKJfvzsNs=";
      };
    }
    {
      path = "node_modules/vscode-languageserver-types";
      src = fetchurl {
        url = "https://registry.npmjs.org/vscode-languageserver-types/-/vscode-languageserver-types-3.17.5.tgz";
        hash = "sha256-1nP55/i75RNRvlHFjzLU3PqXpnDruGvGMzaDlMYJysA=";
      };
    }
  ];
in
stdenvNoCC.mkDerivation {
  pname = "bruno-language-server";
  inherit version src;

  nativeBuildInputs = [
    makeWrapper
    nodejs
    typescript
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export HOME="$TMPDIR"

    cp -r "$src" source
    chmod -R u+w source
    cd source

    ${lib.concatMapStringsSep "\n" (npmSource: ''
      mkdir -p "${npmSource.path}"
      tar -xzf "${npmSource.src}" --strip-components=1 -C "${npmSource.path}"
    '') npmSources}

    ${lib.getExe typescript} -p .

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/libexec/bruno-language-server"
    cp -r out node_modules package.json README.md LICENSE "$out/libexec/bruno-language-server/"

    mkdir -p "$out/bin"
    makeWrapper ${lib.getExe nodejs} "$out/bin/bruno-language-server" \
      --add-flags "$out/libexec/bruno-language-server/out/server.js" \
      --set-default NODE_PATH "$out/libexec/bruno-language-server/node_modules"

    runHook postInstall
  '';

  meta = {
    homepage = "https://github.com/DaviTostes/bruno-language-server";
    description = "Language Server Protocol implementation for Bruno API client";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    mainProgram = "bruno-language-server";
  };
}
