{ config, lib, pkgs, ... }:
let
  homePath = x: "${config.home.homeDirectory}/${x}";
in
{
  home.file."kubeconfig" = {
    executable = false;
    target = ".kube/config.homelab.yaml";
    source = ./kubeconfig.yaml;
  };

  home.sessionVariables = {
    KUBECONFIG = lib.concatStringsSep ":" (map homePath [
      ".kube/config"
      config.home.file."kubeconfig".target
    ]);
  };

  home.packages = with pkgs; [
    k9s
    kubectl
    kubernetes-helm
  ];
}
