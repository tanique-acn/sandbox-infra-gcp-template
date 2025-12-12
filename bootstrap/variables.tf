variable "project" {
  description = "GCP project ID to create resources in"
  type        = string
  default = "sandbox-dev-480919"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "state_bucket_name" {
  description = "Optional: specific bucket name for terraform state. If empty, a unique name will be generated."
  type        = string
  default     = ""
}

variable "service_account_id" {
  description = "ID for the bootstrap service account (will become email {service_account_id}@{project}.iam.gserviceaccount.com)"
  type        = string
  default     = "tf-bootstrap-sa"
}

variable "create_sa_key" {
  description = "Create and output a service account key (sensitive). Set to false if you prefer to create key manually."
  type        = bool
  default     = false
}