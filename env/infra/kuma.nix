{ lib, ... }:

{
  applications.kuma = {
    namespace = "kuma-system";
    createNamespace = true;
    helm.releases.kuma = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://kumahq.github.io/charts";
        chart = "kuma";
        version = "2.10.1";
        chartHash = "sha256-gIaqjHUlyDOSnjIFrBfUayyB8kP/Dwild4ppTKjMfu0=";
      };
      values = {
        egress.enabled = true;
      };
    };
    yamls = [
      (''
        apiVersion: kuma.io/v1alpha1
        kind: Mesh
        metadata:
          name: demo
        spec:
          mtls:
            enabledBackend: ca-1
            backends:
              - name: ca-1
                type: builtin
                dpCert:
                  rotation:
                    expiration: 7d
                conf:
                  caCert:
                    RSAbits: 2048
                    expiration: 10y
      '')
    ];
  };
}
