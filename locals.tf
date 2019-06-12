locals {

  service_account_with_email = "serviceAccount:${var.vault_service_account_email}"

  kms_custom_role_id = "projects/${var.project_name}/roles/${google_project_iam_custom_role.vault-seal-kms.role_id}"
  kms_key_ring       = "${var.kms_key_ring != "" ? var.kms_key_ring : random_id.kms_random.hex}"

  k8s_host = "https://${var.k8s_host}"

  vault_crt = "${tls_locally_signed_cert.vault.cert_pem}\n${tls_self_signed_cert.vault-ca.cert_pem}"

  # Reconstruct with prefix
  vault_ip_name       = "${var.prefix}-${var.vault_ip_name}"
  storage_bucket_name = "${var.prefix}-${var.storage_bucket_name}"
  kms_crypto_key      = "${var.prefix}-${var.kms_crypto_key}"
  vault_secret_name   = "${var.prefix}-${var.vault_secret_name}"
  service_name        = "${var.prefix}-${var.service_name}"
  statefulset_name    = "${var.prefix}-${var.statefulset_name}"
}
