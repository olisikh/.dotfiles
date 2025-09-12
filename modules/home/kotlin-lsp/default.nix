{ namespace, lib, config, pkgs, ... }:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.kotlin-lsp;

  kotlin-lsp = pkgs.fetchzip {
    name = "kotlin-lsp";
    url = "https://download-cdn.jetbrains.com/kotlin-lsp/0.253.10629/kotlin-0.253.10629.zip";
    sha256 = "sha256-LCLGo3Q8/4TYI7z50UdXAbtPNgzFYtmUY/kzo2JCln0=";
    stripRoot = false; # NOTE: archive contains multiple files at the root
  };
in
{
  options.${namespace}.kotlin-lsp = {
    enable = mkBoolOpt false "Enable kotlin-lsp";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        (writeShellScriptBin "kotlin-lsp" ("sh ${kotlin-lsp}/kotlin-lsp.sh $@"))
      ];
    };
  };
}
