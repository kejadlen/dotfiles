resource "kubernetes_persistent_volume_claim" "babybuddy" {
  metadata {
    name = "babybuddy"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "2Gi"
      }
    }
    storage_class_name = "linode-block-storage-retain"
  }
}

resource "kubernetes_deployment" "babybuddy" {
  metadata {
    name = "babybuddy"
  }

  spec {
    selector {
      match_labels = {
        app = "babybuddy"
      }
    }
    strategy {
      type = "Recreate"
    }
    template {
      metadata {
        labels = {
          app = "babybuddy"
        }
      }
      spec {
        container {
          image             = "lscr.io/linuxserver/babybuddy:1.11.1"
          name              = "babybuddy"
          image_pull_policy = "Always"
          port {
            container_port = 8000
          }
          volume_mount {
            name       = "babybuddy"
            mount_path = "/config"
          }
          env {
            name  = "CSRF_TRUSTED_ORIGINS"
            value = "https://babybuddy.${var.domain}"
          }
          env {
            name  = "SECURE_PROXY_SSL_HEADER"
            value = "True"
          }
          env {
            name  = "DEBUG"
            value = "True"
          }
        }
        volume {
          name = "babybuddy"
          persistent_volume_claim {
            claim_name = "babybuddy"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "babybuddy" {
  metadata {
    name = "babybuddy"
  }

  spec {
    port {
      port        = 80
      target_port = 8000
      protocol    = "TCP"
    }
    selector = {
      app = "babybuddy"
    }
  }
}

resource "kubernetes_ingress_v1" "babybuddy" {
  metadata {
    name = "babybuddy"
    annotations = {
      "kubernetes.io/ingress.class"    = "nginx"
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
    }
  }

  spec {
    tls {
      hosts = [
        "babybuddy.${var.domain}"
      ]
      secret_name = "babybuddy-tls"
    }
    rule {
      host = "babybuddy.${var.domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "babybuddy"
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
