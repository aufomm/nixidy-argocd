{
  lib,
  ...
}:
{
  applications.cert-manager = {
    namespace = "cert-manager";
    createNamespace = true;
    helm.releases.cert-manager = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://charts.jetstack.io/";
        chart = "cert-manager";
        version = "v1.17.2";
        chartHash = "sha256-8d/BPet3MNGd8n0r5F1HEW4Rgb/UfdtwqSFuUZTyKl4=";
      };
      values = {
        config.apiVersion = "controller.config.cert-manager.io/v1alpha1";
        config.kind = "ControllerConfiguration";
        config.enableGatewayAPI = true;
        crds.enabled = true;
      };
    };
    yamls = [
      (builtins.readFile ./fomm-ca-cert-secret.sops.yaml)
      (''
        apiVersion: cert-manager.io/v1
        kind: ClusterIssuer
        metadata:
          name: lab-k8s-ca-issuer
        spec:
          ca:
            secretName: fomm-ca-key-pair
      '')
    ];
  };
}
