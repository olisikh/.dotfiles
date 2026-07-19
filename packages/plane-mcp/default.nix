{ lib
, fetchFromGitHub
, fetchPypi
, python312Packages
}:
let
  pythonPackages = python312Packages.overrideScope (_final: prev: {
    inline-snapshot = prev.inline-snapshot.overridePythonAttrs (_: {
      doCheck = false;
    });
    mcp = prev.mcp.overridePythonAttrs (_: {
      doCheck = false;
      nativeCheckInputs = [ ];
    });
    backrefs = prev.backrefs.overridePythonAttrs (_: {
      doCheck = false;
    });
    cyclopts = prev.cyclopts.overridePythonAttrs (_: {
      doCheck = false;
    });
    fastmcp = prev.fastmcp.overridePythonAttrs (_: {
      doCheck = false;
    });
  });
  inherit (pythonPackages) buildPythonApplication buildPythonPackage setuptools requests pydantic fastmcp;

  mcpNoCheck = pythonPackages.mcp.overridePythonAttrs (_: {
    doCheck = false;
    nativeCheckInputs = [ ];
  });

  planeSdk = buildPythonPackage rec {
    pname = "plane-sdk";
    version = "0.2.19";
    pyproject = true;

    src = fetchPypi {
      pname = "plane_sdk";
      inherit version;
      hash = "sha256-c4u3V8Gg9/2s4ahpSGy+f5lOcbcx4joJfLLpgGP8QiU=";
    };

    build-system = [ setuptools ];
    dependencies = [ requests pydantic ];
    pythonImportsCheck = [ "plane" ];
  };
in
buildPythonApplication rec {
  pname = "plane-mcp-server";
  version = "phoenix-487787a";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "makeplane";
    repo = "plane-mcp-server";
    rev = "487787a836c3aff6b2bcbafad3e2b1f460b13b46";
    hash = "sha256-0M5LdjDvEhc+fs/HeBNB35WKrOjEKIb0iQQUAp62Urs=";
  };

  postPatch = ''
    sed -i 's/from plane_mcp.auth import PlaneHeaderAuthProvider, PlaneOAuthProvider/from plane_mcp.auth.plane_header_auth_provider import PlaneHeaderAuthProvider/' plane_mcp/server.py
    sed -i '/^from plane_mcp.storage import build_token_store$/d' plane_mcp/server.py
    sed -i 's/^def get_oauth_mcp(base_path: str = "\/") -> FastMCP:/def get_oauth_mcp(base_path: str = "\/") -> FastMCP:\n    from plane_mcp.auth.plane_oauth_provider import PlaneOAuthProvider\n    from plane_mcp.storage import build_token_store/' plane_mcp/server.py
    sed -i 's/from plane_mcp.server import get_header_mcp, get_oauth_mcp, get_stdio_mcp/from plane_mcp.server import get_header_mcp/' plane_mcp/__main__.py
    sed -i 's/def main() -> None:/def main() -> None:\n    mcp = get_header_mcp()\n    app = mcp.http_app(stateless_http=True)\n    import os, uvicorn\n    uvicorn.run(app, host="127.0.0.1", port=int(os.environ.get("PLANE_MCP_PORT", "8211")), log_level="info", access_log=False)\n\n\ndef _upstream_main() -> None:/' plane_mcp/__main__.py
  '';

  build-system = [ setuptools ];
  dependencies = with pythonPackages; [
    fastmcp
    mcpNoCheck
    planeSdk
  ];

  # The Phoenix source pins versions that nixpkgs has superseded and declares
  # OAuth-only dependencies. The header-only source patch above keeps those
  # code paths lazy. pythonRemoveDeps strips the declared runtime requirements so
  # the Nix-provided packages (fastmcp, mcp, planeSdk) are accepted even though
  # their Python distribution names differ from the upstream metadata.
  pythonRelaxDeps = [ "fastmcp" "mcp" "plane-sdk" ];
  pythonRemoveDeps = [ "fastmcp" "mcp" "plane-sdk" "py-key-value-aio" "authlib" "boto3" "fakeredis" ];
  pythonImportsCheck = [ "plane_mcp" "plane_mcp.server" ];

  meta = {
    description = "Plane MCP server pinned to the Phoenix prerelease source";
    homepage = "https://github.com/makeplane/plane-mcp-server";
    license = lib.licenses.mit;
    mainProgram = "plane-mcp-server";
    platforms = lib.platforms.darwin;
  };
}
