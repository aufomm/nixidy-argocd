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
        controller = {
          ingressController = {
            admissionWebhook = {
              certificate = {
                provided = true;
                secretName = "kong-controller-validation-webhook";
              };
            };
          };
        };
      };
      extraOpts = [
        "--api-versions"
        "gateway.networking.k8s.io/v1"
      ];
    };
    resources = {
      "admissionregistration.k8s.io".v1.ValidatingWebhookConfiguration.kong-controller-kong-validations.metadata =
        {
          annotations."cert-manager.io/inject-ca-from" = "kong/kong-controller-validation-webhook-cert";
        };

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
    yamls = [
      (''
        apiVersion: cert-manager.io/v1
        kind: Certificate
        metadata:
          name: kong-ca-certificate
          namespace: kong
        spec:
          commonName: foMM K8S Kong CA
          isCA: true
          issuerRef:
            kind: ClusterIssuer
            name: lab-k8s-ca-issuer
          secretName: kong-ca-secret
          duration: 43800h  # 5 years
          renewBefore: 1440h  # 2 months
          usages:
          - digital signature
          - key encipherment
          - cert sign
      '')
      (''
        apiVersion: cert-manager.io/v1
        kind: Issuer
        metadata:
          name: kong-ca-issuer
          namespace: kong
        spec:
          ca:
            secretName: kong-ca-secret
      '')
      (''
        apiVersion: cert-manager.io/v1
        kind: Certificate
        metadata:
          name: kong-controller-validation-webhook-cert
          namespace: kong
        spec:
          commonName: kong-controller-validation-webhook.kong.svc
          dnsNames:
          - kong-controller-validation-webhook.kong.svc.cluster.local
          - kong-controller-validation-webhook.kong.svc
          - kong-controller-validation-webhook
          issuerRef:
            kind: Issuer
            name: kong-ca-issuer
          secretName: kong-controller-validation-webhook
          duration: 4380h
          renewBefore: 720h
          usages:
          - digital signature
          - key encipherment
          - server auth
      '')
    ];
  };
}
