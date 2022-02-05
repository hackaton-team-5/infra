resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  namespace  = "hackathon-monitoring"
  values = [
    file("../helm_values/loki.yaml")
  ]
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = "hackathon-monitoring"
  version    = "13.8.0"
  values     = [file("../helm_values/prometheus.yaml")]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = "hackathon-monitoring"
  version    = "6.7.3"
  values     = [file("../helm_values/grafana.yaml")]
}

resource "kubectl_manifest" "certificate_grafana" {
  depends_on = [
    helm_manifest.cluster_issuer
  ]
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: monitoring
  namespace: hackathon-monitoring
spec:
  commonName: monitoring.hackathon-team5-cagip.site
  secretName: monitoring-cert
  dnsNames:
    - monitoring.hackathon-team5-cagip.site
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
YAML
}

resource "kubectl_manifest" "ingress_route_grafana" {
  depends_on = [
    helm_manifest.cluster_issuer
  ]
  yaml_body = <<YAML
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: monitoring
  namespace: hackathon-monitoring
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`monitoring.hackathon-team5-cagip.site`)
      kind: Rule
      services:
        - name: grafana
          port: 80
          namespace: hackathon-monitoring
  tls:
    secretName: monitoring-cert
YAML
}