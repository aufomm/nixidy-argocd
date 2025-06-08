let
  k8s-crd = builtins.fetchurl {
    url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml";
    sha256 = "0r2dssfa38hh0yxmwmx07af4w7h9vqjdsas3qnsvjcrvmgv8nncp";
  };
in
{
  applications.k8s-gw-api-crds = {
    yamls = [
      (builtins.readFile k8s-crd)
    ];
  };
}
