{ lib, ... }:
{
  applications.argocd = {
    namespace = "argocd";
    createNamespace = true;
    helm.releases.argocd = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://argoproj.github.io/argo-helm/";
        chart = "argo-cd";
        version = "8.0.14";
        chartHash = "sha256-75XQBHonKkx2u6msOqt8iwddenNbzbujDWRqGh1I66o=";
      };
      values = {
        configs.secret.argocdServerAdminPassword = "$2a$10$XChYH1h/gF1UEdzapUzQ0Ovgmd8m7sN0uulF2.OKiQeyen2YOVogG";
        server.service = {
          type = "LoadBalancer";
          annotations."metallb.universe.tf/loadBalancerIPs" = "192.168.18.159";
        };
      };
    };
    yamls = [
      (builtins.readFile ./argocd-secrets.sops.yaml)
      (''
        apiVersion: cert-manager.io/v1
        kind: Certificate
        metadata:
          name: argocd-server-cert
          namespace: argocd
        spec:
          secretName: argocd-server-tls
          issuerRef:
            name: lab-k8s-ca-issuer
            kind: ClusterIssuer
          dnsNames:
            - argo.li.k8s
          usages:
            - digital signature
            - key encipherment
            - server auth
      '')
    ];
  };
}
