{
  lib,
  ...
}:
{
  applications.sops-secrets-operator = {
    namespace = "sops-operator";
    createNamespace = true;
    helm.releases.sops = {
      # Use the traefik helm chart from nixhelm.
      chart = lib.helm.downloadHelmChart {
        repo = "https://isindir.github.io/sops-secrets-operator/";
        chart = "sops-secrets-operator";
        version = "0.22.0";
        chartHash = "sha256-+XYYUXKgAQTYntIAqt1bKpHKShxx4OkegwMoUxQ7gh0=";
      };

      values = {
        # Mount secret with age keys to operator pod.
        secretsAsFiles = [
          {
            name = "keys";
            mountPath = "/var/lib/sops/age";
            # Secret created manually out of band.
            secretName = "age-key";
          }
        ];

        # Tell the operator pod where to read age keys.
        extraEnv = [
          {
            name = "SOPS_AGE_KEY_FILE";
            value = "/var/lib/sops/age/key.txt";
          }
        ];
      };
    };
  };
}
