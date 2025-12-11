# GCP Terraform + GitHub Actions CI/CD Sandbox Template

This repository is a starter template for building a DevOps CI/CD pipeline that uses GitHub Actions to run Terraform to manage Google Cloud Platform (GCP) infrastructure.

This updated template includes:
- A bootstrap Terraform module to create the remote state GCS bucket and a service account (and optional key) that can be run in a trusted environment.
- Multi-environment pipeline mapping branches to environments: dev -> DEV, qa -> QA, uat -> UAT, main -> production (PROD).
- CI (validate & plan) runs on pushes and PRs. CD applies on branch pushes or after a successful CI run, gated by GitHub Environments.
- Teardown workflow that supports destroying a specific environment (protected via environment protection or branch restrictions).

New additions:
- docs/environment_protection.md — example environment protection configuration notes with exact approvals recommended.
- scripts/setup_github_secrets.sh — a sample script using the GitHub CLI (gh) to create repository secrets and create the environments (note: environment protections/required reviewers still need to be set via UI or API calls with appropriate permissions; the script helps create the environment objects).

Prerequisites
- gh (GitHub CLI) installed and authenticated with a token that has at least: repo, admin:org (if org-level), and workflow permissions as needed. For environments management via API, gh must be authenticated as a user with permission to manage the repository and its environments.
- A GCP project
- If you prefer, use the bootstrap to create the Terraform remote state GCS bucket and a service account.
- The service account JSON key (if you create a key) stored as a GitHub secret for the workflows.

Required GitHub Secrets (script helps create)
- GCP_SA_KEY — JSON service account key (raw JSON). Workflows set GOOGLE_CREDENTIALS from this value.
- GCP_PROJECT — GCP project ID
- GCP_REGION — default region (e.g., us-central1)
- GCP_ZONE — default zone (e.g., us-central1-a)
- TF_STATE_BUCKET — name of the GCS bucket used for Terraform remote state (bootstrap can create)
- TF_STATE_PREFIX — top-level prefix inside the bucket for state files (e.g., "terraform/state")
- (Optional) TF_VAR_* — any TF variables can be supplied via TF_VAR_* secrets

Branch -> Environment mapping (pipeline)
- dev branch -> environment: dev
- qa branch -> environment: qa
- uat branch -> environment: uat
- main branch -> environment: production (this is your production branch)

Workflows
- .github/workflows/ci.yml
  - Runs on push & pull_request
  - Validates, lints and creates a plan (the CD re-runs the plan before applying)
- .github/workflows/cd.yml
  - Triggers on push to environment branches (dev/qa/uat/main) or a successful CI run
  - Separate jobs per environment (dev/qa/uat/production) with environment protection
  - Re-runs terraform plan then terraform apply (protected by GitHub Environments)
- .github/workflows/teardown.yml
  - Manually triggered
  - Accepts `environment` input (dev/qa/uat/production) to destroy that environment's infrastructure
  - Highly protected — configure GitHub Environments and branch protections before use

Bootstrap (create state bucket + service account)
- bootstrap/main.tf — creates the GCS bucket and a service account and optional key
- bootstrap/README.md — instructions and warnings (do not commit keys to source control)
Note: Running bootstrap will create a service account key (sensitive). Store the key in your secrets manager and add to GitHub Secrets as `GCP_SA_KEY`.

Security notes
- Do NOT commit service account JSON files to the repository.
- For production, tighten IAM permissions granted to the bootstrap-created service account.
- Configure GitHub Environments (dev, qa, uat, production) and require reviewers for QA/UAT/production as needed.

Scripts
- scripts/setup_github_secrets.sh — sample script that uses the GitHub CLI to set repo secrets and create environment entries.

Next steps (recommended)
1. Review `bootstrap/README.md` and run the bootstrap Terraform from a secure environment to create the TF state bucket and a service account (if you want).
2. Run `scripts/setup_github_secrets.sh` to set repository secrets (requires `gh`).
3. Configure environment protections following `docs/environment_protection.md`.
4. Push to `dev` to exercise the pipeline.