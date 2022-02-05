
resource "kubernetes_service_account" "hackathon_ui_user" {
  metadata {
    name      = "hackathon-ui-user"
    namespace = "hackathon-ui"
  }
}

resource "kubernetes_deployment" "hackathon_ui_deployment" {
  metadata {
    name      = "hackathon-ui-deployment"
    namespace = "hackathon-ui"

    labels = {
      app = "hackathon-ui"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "hackathon-ui"
      }
    }

    template {
      metadata {
        labels = {
          app = "hackathon-ui"
        }
      }

      spec {
        container {
          name  = "hackathon-ui"
          image = "cagip/hackathon-ui:latest"

          env {
            name  = "VUE_APP_API_ENDPOINT"
            value = "http://<public_ip_hackathon-api>"
          }

          resources {
            requests = {
              memory = "500Mi"
            }
          }

          liveness_probe {
            http_get {
              path   = "/"
              port   = "80"
              scheme = "HTTP"
            }

            initial_delay_seconds = 10
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path   = "/"
              port   = "80"
              scheme = "HTTP"
            }

            initial_delay_seconds = 10
            timeout_seconds       = 5
          }

          image_pull_policy = "Always"
        }

        service_account_name = "hackathon-ui-user"
      }
    }
  }
}

resource "kubernetes_service" "hackathon_ui_svc" {
  metadata {
    name      = "hackathon-ui-svc"
    namespace = "hackathon-ui"

    labels = {
      app = "hackathon-ui"
    }
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 80
      target_port = "80"
    }

    selector = {
      app = "hackathon-ui"
    }

    cluster_ip = "None"
  }
}
