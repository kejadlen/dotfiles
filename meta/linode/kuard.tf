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
          image             = "gcr.io/kuar-demo/kuard-amd64:1"
          image_pull_policy = "Always"
          name              = "kuard"
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
      port        = 80
      target_port = 8080
      protocol    = "TCP"
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
      "kubernetes.io/ingress.class"    = "nginx"
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
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
          path      = "/"
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
