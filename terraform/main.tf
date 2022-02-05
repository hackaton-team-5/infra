terraform {
  required_providers {
    google = {
      version = "~> 4.9.0"
    }

    kubernetes = {
      version = "~> 2.7.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }

  backend "gcs" {
    bucket  = "hackathon-ca_gip-team5"
    prefix  = "terraform/state"
  }
}

provider "google" {
  project     = "cagip-hackathon-eq05-inno0-27"
  region      = "europe-west1"
}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate,
  )
}

provider "helm" {
  kubernetes {
    host  = "https://${data.google_container_cluster.cluster.endpoint}"
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate,
    )
  }
}

provider "kubectl" {
  host  = "https://${data.google_container_cluster.cluster.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate,
  )
  load_config_file       = false
}


data "google_client_config" "provider" {}

data "google_container_cluster" "cluster" {
  name     = "cluster-demo"
  location = "europe-west1"
}


# Namespaces -----------------------------------------------------------------------
resource "kubernetes_namespace" "hackathon_ui" {
  metadata {
    name = "hackathon-ui"
  }
}

resource "kubernetes_namespace" "hackathon_api" {
  metadata {
    name = "hackathon-api"
  }
}

resource "kubernetes_namespace" "hackathon_monitoring" {
  metadata {
    name = "hackathon-monitoring"
  }
}

resource "kubernetes_namespace" "hackathon_ingress" {
  metadata {
    name = "hackathon-ingress"
  }
}

resource "kubectl_manifest" "certificate_hackathon_api" {
  depends_on = [
    kubectl_manifest.cluster_issuer
  ]
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: api
  namespace: hackathon-api
spec:
  commonName: api.hackathon-team5-cagip.site
  secretName: api-cert
  dnsNames:
    - api.hackathon-team5-cagip.site
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
YAML
}

resource "kubectl_manifest" "ingress_route_hackathon_api" {
  depends_on = [
    kubectl_manifest.cluster_issuer
  ]
  yaml_body = <<YAML
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: api
  namespace: hackathon-api
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`api.hackathon-team5-cagip.site`)
      kind: Rule
      services:
        - name: hackathon-api
          port: 80
          namespace: hackathon-api
  tls:
    secretName: api-cert
YAML
}