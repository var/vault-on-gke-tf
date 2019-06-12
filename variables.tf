
# PROJECT

variable "google_credentials" {
  description = "Your GCP credentials. DO NOT PROVIDE A FILE PATH"
}

variable "project_name" {
  type        = "string"
  description = "GCP project name"
}

variable "region" {
  type        = "string"
  description = "GCP region"
}

variable "zone" {
  type        = "string"
  description = "GCP zone"
}

# NAMES

variable "prefix" {
  type        = "string"
  description = "Prefix without a hyphen."
}

variable "vault_ip_name" {
  type    = "string"
  default = "vault-lb-ip"
}

# SERVICE ACCOUNT

variable "vault_service_account_email" {
  description = "Email of the service account created for this cluster. REQUIRES THE SERVICE ACCOUNT TO EXIST."
}

variable "service_account_iam_roles" {
  type = "list"
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ]
}

variable "service_account_custom_iam_roles" {
  type    = "list"
  default = []

  description = <<EOF
  List of arbitrary additional IAM roles to attach to the service account on
  the Vault nodes.
  EOF
}

# STORAGE BUCKET

variable "storage_bucket_roles" {
  type = "list"

  default = [
    "roles/storage.legacyBucketReader",
    "roles/storage.objectAdmin",
  ]
}

variable "storage_bucket_name" {
  default = "vault-storage-bucket"
}

# KMS

variable "kms_key_rotation_period" {
  default = "604800s"
}

variable "kms_key_ring_prefix" {
  type = "string"
  default = "vault-"

  description = <<EOF
String value to prefix the generated key ring with.
EOF
}

variable "kms_key_ring" {
  type    = "string"
  default = ""

  description = <<EOF
String value to use for the name of the KMS key ring. This exists for
backwards-compatability for users of the existing configurations. Please use
kms_key_ring_prefix instead.
EOF
}

variable "kms_crypto_key" {
  type = "string"
  default = "vault-init"

  description = <<EOF
String value to use for the name of the KMS crypto key.
EOF
}

# K8S

variable "k8s_host" {
  description = "Kubernetes Cluster endpoint"
}

variable "cluster_ca_certificate" {
  description = "cluster_ca_certificate"
}

variable "app_label" {
  description = "app label for metadata"
}

variable "namespace" {
  description = "namespace"
}

variable "service_name" {
  default     = "vault-srv"
  description = "Name of the Kubernetes service"
}

variable "statefulset_name" {
  default = "vault-statefulset"
}

variable "replicas" {
  default     = 3
  description = "number of replicas"
}

variable "vault_disk_name" {
  description = "Name of your volume"
}

# Vault

variable "vault_secret_name" {
  default = "vault-tls"
}

variable "vault_init_container_name" {
  type    = "string"
  default = "vault-init-container"
}

variable "vault_init_image" {
  type        = "string"
  default     = "sethvargo/vault-init:latest"
  description = "Name of the Vault init container image to deploy. This can be specified like container:version or as a full container URL."
}

variable "vault_container_name" {
  type    = "string"
  default = "vault-container"
}

variable "vault_container_image" {
  type    = "string"
  default = "vault:latest"

  description = "Name of the Vault container image to deploy. This can be specified like container:version or as a full container URL."
}

variable "vault_recovery_shares" {
  type    = "string"
  default = "3"

  description = "Number of recovery keys to generate."
}

variable "vault_recovery_threshold" {
  type    = "string"
  default = "3"

  description = "Number of recovery keys required for quorum. This must be less than or equal vault_recovery_keys."
}

# Misc

variable "cert_output_path" {
  default = "./"
}

variable dep_on {
  default = []
  type    = "list"
}
