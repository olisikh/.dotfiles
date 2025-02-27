{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.nix;
in
{
  options.${namespace}.nix = {
    enable = mkBoolOpt false "Enable shared darwin module";
  };

  config = {
    nix = {
      enable = cfg.enable;
      extraOptions = ''
        auto-optimise-store = true
        experimental-features = nix-command flakes
        extra-platforms = x86_64-darwin aarch64-darwin
      '';
    };
  };
}
