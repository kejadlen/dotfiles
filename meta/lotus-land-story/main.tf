terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = ".kube/config"
  }
}

provider "kubernetes" {
  config_path = ".kube/config"
}

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.6.1"
  namespace        = kubernetes_namespace.cert_manager.metadata[0].name

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "kubernetes_manifest" "letsencrypt_staging" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "letsencrypt-staging"
      namespace = "default"
    }
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-staging"
        }
        solvers = [
          {
            selector = {}
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "letsencrypt_prod" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "letsencrypt-prod"
      namespace = "default"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [
          {
            selector = {}
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.0.13"
}

resource "kubernetes_deployment" "kuard" {
  metadata {
    name = "kuard"
  }

  spec {
    selector {
      match_labels = {
        app = "kuard"
      }
    }
    replicas = 1
    template {
      metadata {
        labels = {
          app = "kuard"
        }
      }
      spec {
        container {
          image = "gcr.io/kuar-demo/kuard-amd64:1"
          image_pull_policy = "Always"
          name = "kuard"
          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "kuard" {
  metadata {
    name = "kuard"
  }

  spec {
    port {
      port = 80
      target_port = 8080
      protocol = "TCP"
    }
    selector = {
      app = "kuard"
    }
  }
}

resource "kubernetes_ingress_v1" "kuard" {
  metadata {
    name = "kuard"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "cert-manager.io/issuer" = "letsencrypt-prod"
    }
  }

  spec {
    tls {
      hosts = [
        "kuard.${var.domain}"
      ]
      secret_name = "kuard-tls"
    }
    rule {
      host = "kuard.${var.domain}"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "kuard"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
