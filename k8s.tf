data "google_client_config" "current" {
}

provider "kubernetes" {
  load_config_file = false
  host             = local.k8s_host
  token            = data.google_client_config.current.access_token

  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = var.namespace
    labels = {
      app = var.app_label
    }
  }
}

# Write the secret
resource "kubernetes_secret" "vault-tls" {
  metadata {
    name      = local.vault_secret_name
    namespace = kubernetes_namespace.vault.metadata[0].name
    labels = {
      app = var.app_label
    }
  }

  data = {
    "vault.crt" = local.vault_crt
    "vault.key" = tls_private_key.vault.private_key_pem
    "ca.crt"    = tls_self_signed_cert.vault-ca.cert_pem
  }
}

resource "kubernetes_service" "vault-srv" {
  metadata {
    name      = local.service_name
    namespace = kubernetes_namespace.vault.metadata[0].name

    labels = {
      app = var.app_label
    }
  }

  spec {
    selector = {
      app = var.app_label
    }

    port {
      name        = "vault-port"
      port        = 443
      target_port = 8200
    }

    type = "LoadBalancer"

    load_balancer_ip = google_compute_address.vault-ip.address

    external_traffic_policy = "Local"
  }
}

resource "kubernetes_stateful_set" "vault-statefulset" {
  metadata {
    name      = local.statefulset_name
    namespace = kubernetes_namespace.vault.metadata[0].name

    labels = {
      app = var.app_label
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.app_label
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_label
        }
      }

      spec {
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 60
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key      = "app"
                    operator = "In"
                    values   = [var.app_label]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }
        termination_grace_period_seconds = 10

        container {
          name              = var.vault_init_container_name
          image             = var.vault_init_image
          image_pull_policy = "IfNotPresent"

          resources {
            requests {
              cpu    = "100m"
              memory = "64Mi"
            }
          }

          env {
            name  = "GCS_BUCKET_NAME"
            value = google_storage_bucket.vault.name
          }

          env {
            name  = "VAULT_ADDR"
            value = "http://127.0.0.1:8200"
          }

          env {
            name  = "KMS_KEY_ID"
            value = google_kms_crypto_key.vault-init.id
          }

          env {
            name  = "VAULT_SECRET_SHARES"
            value = var.vault_recovery_shares
          }

          env {
            name  = "VAULT_SECRET_THRESHOLD"
            value = var.vault_recovery_threshold
          }
        }

        container {
          name              = var.vault_container_name
          image             = var.vault_container_image
          image_pull_policy = "IfNotPresent"

          args = ["server"]

          security_context {
            capabilities {
              add = ["IPC_LOCK"]
            }
          }

          port {
            container_port = 8200
          }

          port {
            container_port = 8201
          }

          resources {
            requests {
              cpu    = "500m"
              memory = "256Mi"
            }
          }

          volume_mount {
            mount_path = "/etc/vault/tls"
            name       = var.vault_disk_name
          }

          env {
            name  = "VAULT_ADDR"
            value = "http://127.0.0.1:8200"
          }

          env {
            name = "POD_IP_ADDR"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }

          env {
            name  = "VAULT_LOCAL_CONFIG"
            value = <<EOF
                  api_addr     = "https://${google_compute_address.vault-ip.address}"
                  cluster_addr = "https://$(POD_IP_ADDR):8201"
                  log_level = "warn"
                  ui = true
                  seal "gcpckms" {
                    project    = "${var.project_name}"
                    region     = "${var.region}"
                    key_ring   = "${google_kms_key_ring.vault.name}"
                    crypto_key = "${google_kms_crypto_key.vault-init.name}"
                  }
                  storage "gcs" {
                    bucket     = "${google_storage_bucket.vault.name}"
                    ha_enabled = "true"
                  }
                  listener "tcp" {
                    address     = "127.0.0.1:8200"
                    tls_disable = "true"
                  }
                  listener "tcp" {
                    address       = "$(POD_IP_ADDR):8200"
                    tls_cert_file = "/etc/vault/tls/vault.crt"
                    tls_key_file  = "/etc/vault/tls/vault.key"
                    tls_disable_client_certs = true
                  }
            EOF
          }

          readiness_probe {
            http_get {
              path = "/v1/sys/health?standbyok=true"
              port = 8200
              scheme = "HTTPS"
            }
            initial_delay_seconds = 5
            period_seconds = 5
          }
        }

        volume {
          name = var.vault_disk_name
          secret {
            secret_name = kubernetes_secret.vault-tls.metadata[0].name
          }
        }
      }
    }
    service_name = kubernetes_service.vault-srv.metadata[0].name
  }
}
