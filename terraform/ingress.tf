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