variable "project" {
  description = "GCP project ID"
  type        = string
  default     = "sandbox-dev-480919"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Deployment environment (dev, qa, uat, production)"
  type        = string
  default     = "dev"
}

variable "env_prefix" {
  description = "Optional prefix applied to all resource names (helps multi-repo or shared naming)"
  type        = string
  default     = ""
}

variable "network_name" {
  description = "Base VPC network name (a suffix with environment will be added)"
  type        = string
  default     = "sandbox-vpc"
}

variable "instance_name" {
  description = "Base compute instance name (a suffix with environment will be added)"
  type        = string
  default     = "sandbox-instance"
}

variable "machine_type" {
  description = "Default machine type to use for compute instances"
  type        = string
  default     = "e2-micro"
}

variable "environment_machine_types" {
  description = "Optional per-environment overrides for machine types"
  type        = map(string)
  default = {
    dev        = "e2-micro"
    qa         = "e2-small"
    uat        = "e2-small"
    production = "e2-medium"
  }
}

variable "bucket_name" {
  description = "Optional explicit bucket name. If empty, a name is generated per environment."
  type        = string
  default     = ""
}

variable "subnet_cidr" {
  description = "CIDR range for the environment subnetwork"
  type        = string
  default     = "10.10.0.0/24"
}

variable "tags" {
  description = "Tags to attach to resources (can include environment tag)"
  type        = list(string)
  default     = []
}

# Example: adjust counts or other environment-specific flags via this map if needed
variable "env_flags" {
  description = "Free-form map for environment-specific boolean flags"
  type        = map(any)
  default     = {}
}