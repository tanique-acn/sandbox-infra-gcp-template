# Bootstrap: Create GCS backend bucket & service account

This small Terraform module helps bootstrap the necessary GCP resources required to use the rest of this repository:
- Create the GCS bucket for Terraform remote state
- Create a service account and optional service account key (sensitive)

WARNING: Creating and downloading service account keys is sensitive. Do NOT commit keys to source control. Store keys in your secrets manager (or GitHub Secrets) and rotate them regularly.

How to run
1. Create a directory for bootstrap state locally and run:
   cd bootstrap
   terraform init
   terraform apply

2. After apply, save the generated service account key (if created) securely and add it as a GitHub secret named `GCP_SA_KEY`. Also set `TF_STATE_BUCKET` to the generated bucket name.

Notes
- The bootstrap module will try to create a globally unique bucket name if you do not provide one.
- The service account will be granted the roles required to manage the bucket and basic compute/storage operations. Review and tighten these roles for production.