resource "google_storage_bucket" "vault" {
  name          = local.storage_bucket_name
  project       = var.project_name
  storage_class = "MULTI_REGIONAL"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      num_newer_versions = 1
    }
  }
}

# Grant service account access to the storage bucket
resource "google_storage_bucket_iam_member" "vault-server" {
  count  = length(var.storage_bucket_roles)
  bucket = google_storage_bucket.vault.name
  role   = var.storage_bucket_roles[count.index]
  member = local.service_account_with_email
}
