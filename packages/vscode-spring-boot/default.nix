{ pkgs, ... }:

# Download and extract vscode-spring-boot extension from Open VSX
pkgs.stdenv.mkDerivation rec {
  pname = "vscode-spring-boot";
  version = "2.1.2";

  src = pkgs.fetchurl {
    url = "https://open-vsx.org/api/VMware/vscode-spring-boot/${version}/file/VMware.vscode-spring-boot-${version}.vsix";
    hash = "sha256-zkMDRXBNERTVEPQz12nOtsFfBjNwk6ynYc/gy9iMxHg=";
  };

  nativeBuildInputs = [ pkgs.unzip ];

  unpackPhase = ''
    unzip $src -d vsix-contents
  '';

  installPhase = ''
    mkdir -p $out/share/vscode/extensions/vmware.vscode-spring-boot
    cp -r vsix-contents/extension/* $out/share/vscode/extensions/vmware.vscode-spring-boot/
  '';
}
