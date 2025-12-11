output "bucket_name" {
  description = "GCS bucket name created for terraform state"
  value       = google_storage_bucket.tf_state.name
}

output "service_account_email" {
  description = "Service account email created by the bootstrap"
  value       = google_service_account.bootstrap_sa.email
}

output "service_account_key_base64" {
  description = "Base64-encoded service account private key JSON (sensitive). If create_sa_key = false this will not be present."
  value       = length(google_service_account_key.bootstrap_key) > 0 ? google_service_account_key.bootstrap_key[0].private_key : ""
  sensitive   = true
}