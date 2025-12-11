resource "random_id" "bucket_suffix" {
  # single random id used for bucket uniqueness - this will be different per workspace/state (per environment)
  byte_length = 4
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = local.network_name_full
  auto_create_subnetworks = false
  description             = "VPC for ${local.env_label}"
  routing_mode            = "REGIONAL"
}

# Subnetwork
resource "google_compute_subnetwork" "subnet" {
  name          = local.subnet_name_full
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  description   = "Subnet for ${local.env_label}"
}

# Storage bucket (sample app / artifact bucket)
resource "google_storage_bucket" "app_bucket" {
  name                        = local.bucket_name_full
  location                    = var.region
  uniform_bucket_level_access = true

  labels = {
    environment = local.env_label
    owner       = local.prefix_base
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365
    }
  }
}

# Compute instance
resource "google_compute_instance" "vm" {
  name         = local.instance_name_full
  machine_type = local.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      # ephemeral public IP
    }
  }

  labels = {
    environment = local.env_label
    name        = local.instance_name_full
  }

  tags = local.resource_tags
}

# Example: add optional resource which changes by environment flag
# (This demonstrates how env_flags map can be used)
resource "google_storage_bucket_iam_member" "app_bucket_public" {
  count  = contains(keys(var.env_flags), "make_bucket_public") && tostring(var.env_flags["make_bucket_public"]) == "true" ? 1 : 0
  bucket = google_storage_bucket.app_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}