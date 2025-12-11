This folder holds example .tfvars files for each environment. These files are for local testing only — do NOT commit service account keys or secrets.

Usage examples (local/testing):
  terraform init -backend-config="bucket=BUCKET" -backend-config="prefix=terraform/state/dev"
  terraform apply -var-file=envs/dev.tfvars

In CI the workflows set TF_VAR_environment and other TF_VAR_* values from secrets, so providing these files is optional.