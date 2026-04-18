{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.k8s;
in
{
  options.${namespace}.dev.k8s = {
    enable = mkBoolOpt false "Enable Kubernetes tools (kubectl, minikube, k9s, helm, etc)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      minikube
      k9s
      kubectl
      kubectx
      kubernetes-helm
      kustomize
      etcd
      stern
    ];
  };
}
