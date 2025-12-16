terraform {
  backend "gcs" {
    bucket = "sandbox-dev-480919-tf-state-5d0ea63e"
    prefix = "terraform/state/uat"
  }
}