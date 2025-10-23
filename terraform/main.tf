# terraform/main.tf

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11"
    }
  }
}

# Configure the Kubernetes provider to use our OpenShift cluster's config
# Terraform automatically uses the same config as `kubectl`/`oc`
provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = "devops-project"
  }
}

resource "kubernetes_deployment" "app_deployment" {
  metadata {
    name      = "devops-app-deployment"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app = "devops-app"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "devops-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "devops-app"
        }
      }

      spec {
        container {
          image = "devops-app:1.0" # We will update this later
          name  = "devops-app-container"

          port {
            container_port = 8080
          }
          
          # This is crucial for our debugging scenario
          liveness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app_service" {
  metadata {
    name      = "devops-app-service"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }
  spec {
    selector = {
      app = kubernetes_deployment.app_deployment.spec[0].template[0].metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "NodePort"
  }
}
