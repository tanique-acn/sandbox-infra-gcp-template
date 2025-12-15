locals {
  resource_tags = distinct(concat(["env-${var.environment}"], var.tags))
}