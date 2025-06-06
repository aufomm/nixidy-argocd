{ lib, ... }:
{
  applications.kong = {
    namespace = "kong";
    createNamespace = true;
    annotations."argocd.argoproj.io/sync-wave" = "2";
    helm.releases.kong = {
      chart = lib.helm.downloadHelmChart {
        repo = "https://charts.konghq.com";
        chart = "ingress";
        version = " 0.19.0";
        chartHash = "sha256-GhoK29dTgWxvdWhJdbkjtowy1gUOtpTATf763CbaRTM=";
      };
      values = {
        gateway = {
          image.tag = "3.10";
          image.repository = "kong/kong-gateway";
          admin.http.enabled = true;
          env.router_flavor = "expressions";
          podAnnotations."kuma.io/mesh" = "demo";
          podLabels."kuma.io/sidecar-injection" = "enabled";
          proxy.annotations."metallb.universe.tf/loadBalancerIPs" = "192.168.18.150";
        };
        controller.ingressController.installCRDs = false;
      };
    };
    resources = {
      "rbac.authorization.k8s.io".v1.ClusterRole.kong-controller.rules = [
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "gatewayclasses" ];
          verbs = [
            "get"
            "list"
            "watch"
          ];
        }
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "gatewayclasses/status" ];
          verbs = [
            "get"
            "update"
          ];
        }
        {
          apiGroups = [ "" ];
          resources = [ "namespaces" ];
          verbs = [
            "get"
            "list"
            "watch"
          ];
        }
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "gateways" ];
          verbs = [
            "get"
            "list"
            "update"
            "watch"
          ];
        }
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "gateways/status" ];
          verbs = [
            "get"
            "update"
          ];
        }
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "httproutes" ];
          verbs = [
            "get"
            "list"
            "watch"
          ];
        }
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "httproutes/status" ];
          verbs = [
            "get"
            "update"
          ];
        }
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "referencegrants" ];
          verbs = [
            "get"
            "list"
            "watch"
          ];
        }
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "referencegrants/status" ];
          verbs = [ "get" ];
        }
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "tcproutes" ];
          verbs = [
            "get"
            "list"
            "watch"
          ];
        }
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "tcproutes/status" ];
          verbs = [
            "get"
            "update"
          ];
        }
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "tlsroutes" ];
          verbs = [
            "get"
            "list"
            "watch"
          ];
        }
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "tlsroutes/status" ];
          verbs = [
            "get"
            "update"
          ];
        }
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "udproutes" ];
          verbs = [
            "get"
            "list"
            "watch"
          ];
        }
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "udproutes/status" ];
          verbs = [
            "get"
            "update"
          ];
        }
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "grpcroutes" ];
          verbs = [
            "get"
            "list"
            "watch"
          ];
        }
        {
          apiGroups = [ "gateway.networking.k8s.io" ];
          resources = [ "grpcroutes/status" ];
          verbs = [
            "get"
            "patch"
            "update"
          ];
        }
      ];
      gatewayClasses.kong = {
        metadata = {
          name = "kong";
          annotations = {
            "konghq.com/gatewayclass-unmanaged" = "true";
          };
        };
        spec = {
          controllerName = "konghq.com/kic-gateway-controller";
        };
      };

      # Gateway
      gateways.kong = {
        metadata = {
          name = "kong";
          namespace = "kong";
          annotations = {
            "cert-manager.io/cluster-issuer" = "lab-k8s-ca-issuer";
          };
        };
        spec = {
          gatewayClassName = "kong";
          listeners = [
            {
              name = "proxy";
              port = 80;
              protocol = "HTTP";
              allowedRoutes = {
                namespaces = {
                  from = "All";
                };
              };
            }
            {
              name = "proxy-tls";
              hostname = "proxy.li.k8s";
              port = 443;
              protocol = "HTTPS";
              allowedRoutes = {
                namespaces = {
                  from = "All";
                };
              };
              tls = {
                mode = "Terminate";
                certificateRefs = [
                  {
                    name = "proxy-cert";
                  }
                ];
              };
            }
          ];
        };
      };
    };
  };
}
