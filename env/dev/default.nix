{ lib, ... }:
let
  env = "dev";
in
{
  nixidy = {
    target.repository = "git@github.com:aufomm/nixidy-argocd.git";
    target.branch = "main";
    target.rootPath = "./manifests/${env}";
    defaults = {
      syncPolicy = {
        autoSync = {
          enabled = true;
          prune = true;
          selfHeal = true;
        };
      };
      destination.server = "https://kubernetes.default.svc";
      helm.transformer = map (
        lib.kube.removeLabels [
          "app.kubernetes.io/version"
          "helm.sh/chart"
          "app.kubernetes.io/managed-by"
        ]
      );
    };
    appOfApps.name = "${env}-apps";
    appOfApps.namespace = "argocd";
    resourceImports = [
      ../modules/gateway-api.nix
    ];
  };

  imports = [
    ./httpbin
    ./kong
  ];
}
