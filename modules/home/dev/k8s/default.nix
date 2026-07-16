{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (lib.${namespace}.zsh) mkLate;

  cfg = config.${namespace}.dev.k8s;
in
{
  options.${namespace}.dev.k8s = {
    enable = mkBoolOpt false "Enable Kubernetes tools (minikube includes kubectl, k9s, helm, etc)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      minikube
      k9s
      kubectx
      kubernetes-helm
      kustomize
      etcd
      stern
      kops
    ];

    programs.zsh.initContent = mkLate
      # zsh
      ''
        eval "$(kops completion zsh)"
      '';
  };
}
