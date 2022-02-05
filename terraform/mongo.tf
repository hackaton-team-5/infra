resource "kubernetes_cluster_role_binding" "default" {
  metadata {
    name = "default"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "hackathon-api"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "admin"
  }
}

resource "kubernetes_storage_class" "fast" {
  metadata {
    name = "fast"
  }
  storage_provisioner = "kubernetes.io/gce-pd"

  parameters = {
    type = "pd-ssd"
  }
}

resource "kubernetes_service" "mongo" {
  metadata {
    name      = "mongo"
    namespace = "hackathon-api"

    labels = {
      name = "mongo"
    }
  }

  spec {
    port {
      port        = 27017
      target_port = 27017
    }

    selector = {
      app = "mongo"
    }

    cluster_ip = "None"
  }
}

resource "kubernetes_stateful_set" "mongo" {
  metadata {
    name      = "mongo"
    namespace = "hackathon-api"

    labels = {
      app = "mongo"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "mongo"
      }
    }

    template {
      metadata {
        labels = {
          app = "mongo"
        }
      }

      spec {
        container {
          name    = "mongo"
          image   = "mongo"
          command = ["mongod", "--bind_ip", "0.0.0.0", "--replSet", "MainRepSet"]

          port {
            container_port = 27017
          }

          volume_mount {
            name       = "mongo-persistent-storage"
            mount_path = "/data/db"
          }
        }

        container {
          name  = "mongo-sidecar"
          image = "cvallance/mongo-k8s-sidecar"

          env {
            name  = "MONGO_SIDECAR_POD_LABELS"
            value = "app=mongo"
          }
        }

        termination_grace_period_seconds = 10
      }
    }

    volume_claim_template {
      metadata {
        name = "mongo-persistent-storage"

        annotations = {
          "volume.beta.kubernetes.io/storage-class" = "fast"
        }
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        resources {
          requests = {
            storage = "200Gi"
          }
        }
      }
    }

    service_name = "mongo"
  }
}

# DO NOT UNCOMMENT THOSE LINE (Already applied)
# resource "kubernetes_job" "mongo_index" {
#   metadata {
#     name      = "mongo-index"
#     namespace = "hackathon-api"
#   }

#   spec {
#     backoff_limit = 4

#     template {
#       metadata {}

#       spec {
#         container {
#           name    = "mongo-index"
#           image   = "mongoclient/mongoclient"
#           command = [
#             "sh", "-c", 
#             "sleep 60; MASTER=`mongo --host mongo-0.mongo --quiet --eval \"db.isMaster().ismaster\"`; if $MASTER; then\n  mongo --host mongo-0.mongo --eval 'db.donations.createIndex({ \"donatorName\": 1 })' donation;\n  mongo --host mongo-0.mongo --eval 'db.donations.createIndex({ \"amount\": 1 })' donation;\n  mongo --host mongo-0.mongo --eval 'db.donations.createIndex({ \"moneyType\": 1 })' donation;\n  mongo --host mongo-0.mongo --eval 'db.donations.createIndex({ \"pdfRef\": 1 })' donation;\n  mongo --host mongo-0.mongo --eval 'db.donations.createIndex({ \"donatorName\": 1, \"moneyType\": 1 })' donation;\n  mongo --host mongo-0.mongo --eval 'db.donations.createIndex({ \"donatorName\": 1, \"amount\": 1 })' donation;\n  mongo --host mongo-0.mongo --eval 'db.donations.createIndex({ \"amount\": 1, \"moneyType\": 1 })' donation;\n  mongo --host mongo-0.mongo --eval 'db.donations.createIndex({ \"donatorName\": -1 })' donation;\n  mongo --host mongo-0.mongo --eval 'db.donations.createIndex({ \"amount\": -1 })' donation;\n  mongo --host mongo-0.mongo --eval 'db.donations.createIndex({ \"moneyType\": -1 })' donation;\n  mongo --host mongo-0.mongo --eval 'db.donations.createIndex({ \"pdfRef\": -1 })' donation;\n  mongo --host mongo-0.mongo --eval 'db.donations.createIndex({ \"donatorName\": -1, \"moneyType\": -1 })' donation;\n  mongo --host mongo-0.mongo --eval 'db.donations.createIndex({ \"donatorName\": -1, \"amount\": -1 })' donation;\n  mongo --host mongo-0.mongo --eval 'db.donations.createIndex({ \"amount\": -1, \"moneyType\": -1 })' donation;\n  mongo --host mongo-0.mongo --eval 'db.donations.aggregate([{ $indexStats: { }}])' donation;\nfi\n"]
#         }

#         restart_policy = "Never"
#       }
#     }
#   }
# }
