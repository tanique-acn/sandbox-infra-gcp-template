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
  description = "Deployment Environment"
  type        = string
  default     = "dev"
}

variable "machine_type" {
  description = "Instance Machine Types"
  type        = map(string)
  default = {
    micro  = "e2-micro"
    small  = "e2-small"
    medium = "e2-medium"
  }
}

variable "machine_image_type" {
  description = "Instance Machine Image Types"
  type        = map(string)
  default = {
    debian  = "debian-cloud/debian-12"
    centos  = "centos-cloud/centos-10"
    rhel    = "rhel-cloud/debian-10"
    windows = "windows-cloud/windows-2022"
  }
}

variable "machine_disk_size" {
  description = "Instance Boot Disk Sizes"
  type        = map(number)
  default = {
    micro  = 10
    small  = 20
    medium = 50
    large  = 100
  }
}

variable "subnet_cidr" {
  description = "CIDR range for the environment subnetwork"
  type        = string
  default     = "10.10.0.0/24"
}

variable "tags" {
  description = "Tags to attach to resources (can include environment tag)"
  type        = list(string)
  default     = ["sandbox"]
}