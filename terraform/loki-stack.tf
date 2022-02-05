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

