# output "environment" {
#   description = "Target environment for this deployment"
#   value       = var.environment
# }

# output "network_name" {
#   description = "Name of the created VPC network"
#   value       = google_compute_network.vpc.name
# }

# output "subnet_name" {
#   description = "Name of the created subnet"
#   value       = google_compute_subnetwork.subnet.name
# }

# output "instance_name" {
#   description = "Name of the created compute instance"
#   value       = google_compute_instance.vm.name
# }

# output "instance_external_ip" {
#   description = "External IP of the compute instance (may be empty if none assigned yet)"
#   value       = try(google_compute_instance.vm.network_interface[0].access_config[0].nat_ip, "")
#   sensitive   = false
# }

# output "bucket_name" {
#   description = "Name of the created storage bucket"
#   value       = google_storage_bucket.app_bucket.name
# }