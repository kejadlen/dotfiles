terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "1.16.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "=2.1.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "kube.config.private"
  }
}

provider "kubernetes" {
  config_path = "kube.config.private"
}

provider "linode" {
  # token = "$LINODE_TOKEN"
}

resource "linode_lke_cluster" "ramble-hard" {
  label       = "ramble-hard"
  k8s_version = "1.20"
  region      = "us-west"

  pool {
    type  = "g6-standard-1"
    count = 1
  }
}

resource "kubernetes_namespace" "ingress-traefik-namespace" {
  depends_on = [local_file.kubeconfig]

  metadata {
    annotations = {
      name = "traefik"
    }
    name = "traefik"
  }
}

resource "helm_release" "ingress-traefik" {
  depends_on = [local_file.kubeconfig]

  name       = "traefik"
  chart      = "traefik"
  repository = "https://helm.traefik.io/traefik"
  namespace  = "traefik"

  values = [
    file("traefik.yml")
  ]
}

resource "kubernetes_namespace" "cert-manager-namespace" {
  depends_on = [local_file.kubeconfig]

  metadata {
    annotations = {
      name = "cert-manager"
    }
    name = "cert-manager"
  }
}

resource "helm_release" "cert-manager" {
  depends_on = [local_file.kubeconfig]

  name       = "cert-manager"
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  namespace  = "cert-manager"

  set {
    name  = "installCRDs"
    value = "true"
  }
}
