{ lib, config, namespace, pkgs, ... }:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.virtualization.vagrant;

  # Extract zsh completion script from vagrant gem into its own derivation
  vagrantZshCompletion = pkgs.runCommand "vagrant-zsh-completion" {
    nativeBuildInputs = [ pkgs.findutils ];
  } ''
    mkdir -p $out/share/zsh/site-functions
    find ${pkgs.vagrant}/lib/ruby/gems -type f -path '*/contrib/zsh/_vagrant' \
      -exec cp {} $out/share/zsh/site-functions/_vagrant \;
  '';
in
{
  options.${namespace}.dev.virtualization.vagrant = {
    enable = mkBoolOpt false "Enable vagrant module";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      vagrant
      vagrantZshCompletion
    ];
  };
}
