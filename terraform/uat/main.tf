# # VPC
# resource "google_compute_network" "vpc" {
#   name                    = "sandbox-vpc-${var.environment}"
#   auto_create_subnetworks = false
#   description             = "VPC for ${var.environment}"
#   routing_mode            = "REGIONAL"
# }

# # Subnetwork
# resource "google_compute_subnetwork" "subnet" {
#   name          = "sandbox-subnet-${var.environment}"
#   ip_cidr_range = var.subnet_cidr
#   region        = var.region
#   network       = google_compute_network.vpc.id
#   description   = "Subnet for ${var.environment}"
# }

# # App Storage Bucket
# resource "google_storage_bucket" "app_bucket" {
#   name                        = "sandbox-app-bucket-${var.environment}"
#   location                    = var.region
#   uniform_bucket_level_access = true

#   labels = {
#     environment = var.environment
#     owner       = var.project
#   }

#   lifecycle_rule {
#     action {
#       type = "Delete"
#     }
#     condition {
#       age = 30
#     }
#   }
# }

# # Compute Instance
# resource "google_compute_instance" "vm" {
#   name         = "sandbox-vm-${var.environment}"
#   machine_type = var.machine_type.medium
#   zone         = var.zone

#   boot_disk {
#     initialize_params {
#       image = var.machine_image_type.rhel
#       size  = var.machine_disk_size.medium
#     }
#   }

#   network_interface {
#     network    = google_compute_network.vpc.id
#     subnetwork = google_compute_subnetwork.subnet.id

#     access_config {
#       # ephemeral public IP
#     }
#   }

#   labels = {
#     environment = var.environment
#     owner       = var.project
#   }

#   tags = local.resource_tags
# }