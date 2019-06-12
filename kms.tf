resource "random_id" "kms_random" {
  prefix      = var.kms_key_ring_prefix
  byte_length = "8"
}

# Create the KMS key ring
resource "google_kms_key_ring" "vault" {
  name     = local.kms_key_ring
  location = var.region
  project  = var.project_name
}

# Create the crypto key for encrypting init keys
resource "google_kms_crypto_key" "vault-init" {
  name            = local.kms_crypto_key
  key_ring        = google_kms_key_ring.vault.id
  rotation_period = var.kms_key_rotation_period
}

resource "google_project_iam_custom_role" "vault-seal-kms" {
  project     = var.project_name
  role_id     = "kmsEncrypterDecryptorViewer"
  title       = "KMS Encrypter Decryptor Viewer"
  description = "KMS crypto key permissions to encrypt, decrypt, and view key data"

  permissions = [
    "cloudkms.cryptoKeyVersions.useToEncrypt",
    "cloudkms.cryptoKeyVersions.useToDecrypt",

    # This is required until hashicorp/vault#5999 is merged. The auto-unsealer
    # attempts to read the key, which requires this additional permission.
    "cloudkms.cryptoKeys.get",
  ]
}

resource "google_kms_crypto_key_iam_member" "vault-init" {
  crypto_key_id = google_kms_crypto_key.vault-init.id
  role          = local.kms_custom_role_id
  member        = local.service_account_with_email
}
