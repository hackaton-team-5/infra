terraform {
  required_providers {
    google = {
      version = "~> 4.9.0"
    }

    kubernetes = {
      version = "~> 2.7.1"
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
