terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  bucket_name = var.state_bucket_name != "" ? var.state_bucket_name : "${var.project}-tf-state-${random_id.bucket_suffix.hex}"
}

resource "google_storage_bucket" "tf_state" {
  name     = local.bucket_name
  location = var.region

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }
}

resource "google_service_account" "bootstrap_sa" {
  account_id   = var.service_account_id
  display_name = "Terraform bootstrap service account"
}

# Grant the SA the permissions needed to manage the backend bucket and create basic resources.
resource "google_project_iam_member" "sa_storage_admin" {
  project = var.project
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.bootstrap_sa.email}"
}

resource "google_project_iam_member" "sa_compute_admin" {
  project = var.project
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.bootstrap_sa.email}"
}

# Optional: create a service account key (sensitive). If you prefer additional security,
# set create_sa_key = false and create a key manually using gcloud on a trusted machine.
resource "google_service_account_key" "bootstrap_key" {
  count              = var.create_sa_key ? 1 : 0
  service_account_id = google_service_account.bootstrap_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
  # private_key is output as base64 in google_service_account_key.private_key
}