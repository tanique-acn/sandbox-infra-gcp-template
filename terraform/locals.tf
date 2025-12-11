locals {
  # Prefix: optionally include a custom prefix, otherwise use project id (shortened) to avoid overly long names
  prefix_base = trimspace(var.env_prefix != "" ? var.env_prefix : (length(var.project) > 0 ? var.project : "tf"))

  # sanitized environment label (lowercase)
  env_label = lower(var.environment)

  # name_prefix used for resource names
  name_prefix = "${local.prefix_base}-${local.env_label}"

  # compute machine type: per-environment override falls back to var.machine_type
  machine_type = lookup(var.environment_machine_types, local.env_label, var.machine_type)

  # resource names
  network_name_full  = "${var.network_name}-${local.env_label}"
  subnet_name_full   = "${local.network_name_full}-subnet"
  instance_name_full = "${var.instance_name}-${local.env_label}"
  bucket_name_full   = var.bucket_name != "" ? var.bucket_name : "${local.name_prefix}-app-bucket-${random_id.bucket_suffix.hex}"

  # additional tags always include environment
  resource_tags = distinct(concat(["env:${local.env_label}"], var.tags))
}