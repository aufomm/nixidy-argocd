{ lib, ... }:
let
  policiesYamls = lib.kube.readYamlsFromDir {
    dir = ./policies;
  };
in
{
  applications.httpbin = {
    namespace = "httpbin";
    createNamespace = false;
    resources =
      let
        labels = {
          "app.kubernetes.io/name" = "httpbin";
        };
      in
      {
        deployments.httpbin.spec = {
          selector.matchLabels = labels;
          template = {
            metadata.labels = labels;
            spec = {
              containers.httpbin = {
                image = "mccutchen/go-httpbin:v2.15.0";
              };
            };
          };
        };
        services.httpbin-svc = {
          metadata.annotations."ingress.kubernetes.io/service-upstream" = "true";
          spec = {
            selector = labels;
            ports.http = {
              port = 80;
              appProtocol = "http";
              targetPort = 8080;
            };
          };
        };
        hTTPRoutes.httpbin-bin-route = {
          metadata.annotations."konghq.com/strip-path" = "true";
          spec = {
            hostnames = [ "proxy.li.k8s" ];
            parentRefs = [
              {
                group = "gateway.networking.k8s.io";
                kind = "Gateway";
                name = "kong";
                namespace = "kong";
              }
            ];
            rules = [
              {
                matches = [
                  {
                    path = {
                      type = "PathPrefix";
                      value = "/bin";
                    };
                  }
                ];
                backendRefs = [
                  {
                    name = "httpbin-svc";
                    kind = "Service";
                    port = 80;
                  }
                ];
              }
            ];
          };
        };
      };

    # Combine static YAML and dynamically read files
    yamls = [
      ''
        apiVersion: v1
        kind: Namespace
        metadata:
          name: httpbin
          labels:
            shared-gateway-access: "true"
            kuma.io/sidecar-injection: enabled
          annotations:
            kuma.io/mesh: demo
      ''
    ] ++ policiesYamls;
  };
}
