resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"
  namespace  = "hackathon-ingress"

  values = [
    file("../helm_values/traefik.yaml")
  ]
}

data "kubernetes_service" "traefik" {
  depends_on = [
    helm_release.traefik
  ]
  metadata {
    name      = "traefik"
    namespace = "hackathon-ingress"
  }
}

# Install helm release Cert Manager
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  namespace  = "hackathon-ingress"

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "kubectl_manifest" "cluster_issuer" {
  depends_on = [
    helm_release.cert_manager
  ]
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
  namespace: hackathon-ingress
spec:
  acme:
    email: bouthinon.alexandre@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt
    solvers:
      - http01:
          ingress:
            class: traefik-cert-manager
YAML
}