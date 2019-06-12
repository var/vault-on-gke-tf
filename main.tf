provider "google" {
  credentials = var.google_credentials
  project     = var.project_name
  region      = var.region
  zone        = var.zone
}

resource "google_compute_address" "vault-ip" {
  name    = local.vault_ip_name
  region  = var.region
  project = var.project_name
}

# Add the service account to the project
resource "google_project_iam_member" "service-account" {
  count   = length(var.service_account_iam_roles)
  project = var.project_name
  role    = var.service_account_iam_roles[count.index]
  member  = local.service_account_with_email
}

# Add user-specified roles
resource "google_project_iam_member" "service-account-custom" {
  count   = length(var.service_account_custom_iam_roles)
  project = var.project_name
  role    = var.service_account_custom_iam_roles[count.index]
  member  = local.service_account_with_email
}
