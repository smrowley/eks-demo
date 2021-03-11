# Kubernetes provider
# https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster#optional-configure-terraform-kubernetes-provider
# To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/terraform/kubernetes/deploy-nginx-kubernetes

# The Kubernetes provider is included in this file so the EKS module can complete successfully. Otherwise, it throws an error when creating `kubernetes_config_map.aws_auth`.
# You should **not** schedule deployments and services in this workspace. This keeps workspaces modular (one for provision EKS, another for scheduling Kubernetes resources) as per best practices.

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.cluster.name
    ]
  }
}

locals {
  namespace = "koncepts"
  app_name = "koncepts-demo"
}

resource "kubernetes_namespace" "koncepts" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_deployment" "koncepts_demo" {
  metadata {
    name = local.app_name
    namespace = local.namespace
    labels = {
      "app" = local.app_name
    }
  }
  spec {
    strategy {
      type = "RollingUpdate"
    }
    replicas = 1
    selector {
      match_labels = {
        "app" = local.app_name
      }
    }
    template {
      metadata {
        labels = {
          "app" = local.app_name
        }
      }
      spec {
        container {
          name = local.app_name
          image = "srowley/koncepts:latest"
          image_pull_policy = "Always"
          port {
            name = "http"
            container_port = 8080
            protocol = "TCP"
          }
          port {
            name = "metrics"
            container_port = 8081
            protocol = "TCP"
          }
        }
      }
    }
  }

  depends_on = [
    module.eks
  ]
}

resource "kubernetes_service" "koncepts_demo" {
  metadata {
    name = "${local.app_name}-lb"
    namespace = local.namespace
  }
  spec {
    selector = {
      "app" = local.app_name
    }
    type = "LoadBalancer"
    port {
      name = "http"
      protocol = "TCP"
      port = 80
      target_port = "8080"
    }
  }

  depends_on = [
    module.eks
  ]
}