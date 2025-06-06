{ lib, ... }:
let
  knownPorts = {
    control-plane = [
      {
        port = 5680;
        name = "diagnostics";
      }
      { port = 5681; }
      { port = 5682; }
      { port = 5443; }
    ];
    egress = [
      { port = 10002; }
      { port = 9901; }
    ];
  };
in
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
    /*
      NOTE: mkForce is used here because:
      1. The type system requires concrete port definitions
      2. We need to ensure protocol: TCP is set for all ports
      3. Port merging isn't working as expected with the current module structure
      TODO: Monitor for new ports in upstream releases https://artifacthub.io/packages/helm/kuma/kuma
    */
    resources.deployments = {
      kuma-control-plane.spec.template.spec.containers.control-plane.ports = lib.mkForce (
        map (cfg: lib.kube.addProtocolToPort cfg) knownPorts.control-plane
      );

      kuma-egress.spec.template.spec.containers.egress.ports = lib.mkForce (
        map (cfg: lib.kube.addProtocolToPort cfg) knownPorts.egress
      );
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
