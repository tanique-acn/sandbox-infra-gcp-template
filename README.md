# GCP Terraform + GitHub Actions CI/CD Sandbox Template

This repository is a starter template for a multi-environment CI/CD pipeline using GitHub Actions and Terraform to manage Google Cloud Platform (GCP) infrastructure.

Summary of important features
- Multi-environment flow: dev -> qa -> uat -> main (production)
- Each environment uses its own independent GCP project (per-environment secrets)
- Environment-specific GitHub Environment protection for UAT and Production (manual approvals)
- Bootstrapping folder to create the Terraform state bucket and a service account (run from a trusted machine)
- A setup script to create repository and per-environment secrets and environment placeholders (uses GitHub CLI `gh`)
- Workflows:
  - .github/workflows/ci.yml — CI: validate, lint, plan (artifact)
  - .github/workflows/cd.yml — CD: re-plan and apply per-environment, with approval jobs for UAT/Prod
  - .github/workflows/destroy.yml — Manual destroy per-environment

Why README needed updating
- The repo now supports one GCP project per environment. The README must document the required per-environment secrets and how to create them.
- Document bootstrap usage (create TF state bucket + SA).
- Document the setup script usage (creating secrets and placeholder environments).
- Explain branch→environment mapping and environment protections/approvals required for UAT/Production.
- Provide quick validation and troubleshooting steps.

Updated content and important items (this file)

Prerequisites
- GitHub CLI (`gh`) installed and authenticated with a token that has repo admin privileges for the repository.
- GCP access from a trusted environment to run bootstrap (if you will use bootstrap to create state bucket and SA).
- If you will not run bootstrap, pre-create:
  - A GCS bucket to host Terraform remote state (or use bootstrap to create it)
  - A service account in each environment's GCP project (recommended) or a single SA with access to all projects (less ideal)

Branch → environment mapping
- dev branch → environment: dev
- qa branch → environment: qa
- uat branch → environment: uat
- main branch → environment: production (PROD)

Required repository secrets (created by scripts/setup_github_secrets.sh or manually)
- Global fallback (optional):
  - GCP_SA_KEY — main service account JSON (fallback)
  - GCP_PROJECT — fallback project id
  - GCP_REGION, GCP_ZONE
  - TF_STATE_BUCKET — name of the GCS bucket used for Terraform remote state
  - TF_STATE_PREFIX — prefix inside the bucket (e.g., `terraform/state`)
- Per-environment (recommended):
  - GCP_PROJECT_DEV / GCP_PROJECT_QA / GCP_PROJECT_UAT / GCP_PROJECT_PRODUCTION
  - GCP_SA_KEY_DEV / GCP_SA_KEY_QA / GCP_SA_KEY_UAT / GCP_SA_KEY_PRODUCTION
    - These are repository-level secrets with names used by the workflows. The setup script can create them using per-environment JSON key files or by reusing the main SA JSON.
- (Optional) Environment-scoped secrets via the Environments UI if you want secrets bound to GitHub Environments.

Bootstrap (optional, recommended for convenience)
- Directory: `bootstrap/`
- Purpose: create the GCS bucket for Terraform state and create a bootstrap service account (and optionally a key).
- Run from a secure machine (not in a public runner if you need to download keys).
  Example:
    cd bootstrap
    terraform init
    terraform apply
- After bootstrap completes:
  - Record the generated bucket name and service account key (if created).
  - Securely store the service account key and add it to GitHub Secrets.

Setup script (automates creating secrets and environment placeholders)
- Script: `scripts/setup_github_secrets.sh`
- Requirements:
  - `gh` (GitHub CLI) installed and authenticated with repo admin privileges
- Typical usage (example):
  ./scripts/setup_github_secrets.sh \
    --sa-key-path ./gcp-sa.json \
    --project fallback-project-id \
    --project-dev dev-project-id \
    --project-qa qa-project-id \
    --project-uat uat-project-id \
    --project-prod prod-project-id \
    --region us-central1 \
    --zone us-central1-a \
    --tf-bucket my-tf-state-bucket \
    --tf-prefix terraform/state \
    --env-sa-keys-dir ./env-keys
- Notes:
  - If `--env-sa-keys-dir` is provided, it should contain `dev.json`, `qa.json`, `uat.json`, `production.json` to create per-environment SA keys. Otherwise the script uses the single `--sa-key-path` key as fallback.
  - The script will create repository secrets:
    - GCP_SA_KEY (fallback), GCP_PROJECT (fallback), TF_STATE_BUCKET, TF_STATE_PREFIX, GCP_REGION, GCP_ZONE
    - Per-environment: GCP_PROJECT_DEV/QA/UAT/PRODUCTION and GCP_SA_KEY_DEV/QA/UAT/PRODUCTION
  - The script will create environment placeholders (dev, qa, uat, production). Protection rules/required reviewers must be configured separately.

Workflows behavior (quick)
- CI (ci.yml):
  - Runs on pushes and PRs to any branch.
  - Detects target environment from branch name.
  - Loads per-environment credentials from secrets (falling back to repo-level secrets if necessary).
  - Runs fmt, init (backend), validate, lint, plan and uploads plan artifact.
- CD (cd.yml):
  - Triggers on pushes to environment branches and on successful CI workflow runs.
  - Runs separate jobs for dev, qa, uat and production.
  - DEV and QA apply automatically (DEV expected to be low-friction; QA optional required reviewers in environment settings).
  - UAT and PRODUCTION require manual approval: the workflow includes dedicated "Await UAT approval" and "Await Production approval" jobs that are scoped to the respective GitHub Environment. Those jobs will pause until an approver configured in the environment approves the deployment. After approval, the dependent apply job runs.
  - Each apply job re-runs terraform plan (using environment-specific project and credentials) and then applies.
- destroy (destroy.yml):
  - Manual workflow_dispatch that accepts an `environment` input (dev/qa/uat/production)
  - Uses per-environment credentials and destroys resources in that environment's project and state prefix.

Terraform configuration notes
- The Terraform code is environment-agnostic: resources are created per environment by passing `environment` and `env_prefix` (or by using per-environment tfvars in `terraform/envs/` for local testing).
- Remote state is isolated by using `TF_STATE_PREFIX` + environment name (passed to `terraform init -backend-config="prefix=..."` in workflows).
- Per-environment GCP project is passed via `-var="project=..."` and via `TF_VAR_project` so resources are created in the correct GCP project.
- Resource names include the environment suffix to avoid collisions between environments.

Environment protection recommendations
- Configure GitHub Environments:
  - dev: optional reviewers, allow Actions
  - qa: require 1 reviewer (optional)
  - uat: require 1–2 reviewers; restrict branch to `uat`; require Actions for deployment (manual approval will be enforced by the workflow's wait job)
  - production: require 2+ approvers; restrict branch to `main`; enforce environment-level secrets and restrict who can deploy
- See `docs/environment_protection.md` for details and examples.

Testing and quick start
1. (Optional) Run bootstrap to create state bucket and service account:
   cd bootstrap && terraform init && terraform apply
   Save the service account key (if created) securely.
2. Run the setup script to create repo and per-env secrets:
   ./scripts/setup_github_secrets.sh --sa-key-path ./gcp-sa.json --project <fallback> \
     --project-dev <dev-project> --project-qa <qa-project> --project-uat <uat-project> --project-prod <prod-project> \
     --region <region> --zone <zone> --tf-bucket <state-bucket> --tf-prefix terraform/state
3. In GitHub: go to Settings → Environments and configure protection rules for UAT and Production (required reviewers).
4. Push to `dev` branch to execute CI + CD for DEV.
5. Verify UAT/Production pushes pause in the CD workflow and require approval.

Security and operational notes
- Do NOT commit service account keys to source control.
- Prefer creating short-lived or limited-permission service accounts per environment instead of a single wide-permission SA.
- Rotate keys regularly.
- Consider the cost implications of provisioning resources across multiple projects/environments; add Infracost to CI if desired.
- If you need to provision GCP projects automatically you will require organization-level permissions; that is not included here by default.

Troubleshooting
- "Missing secret" errors: confirm per-environment secrets (GCP_SA_KEY_*, GCP_PROJECT_*) exist and contain the expected values.
- Terraform backend init errors: confirm TF_STATE_BUCKET exists and is accessible by the service account in the target project (bootstrap can create the bucket in a chosen project; alternatively create buckets per environment).
- Approvals not pausing: ensure the CD workflow job that waits for approval uses the `environment:` property and that the GitHub Environment has required reviewers configured.
- If you want environment-scoped secrets instead of repo-level per-environment secrets, the setup script can be adapted; note that environment-scoped secrets are created in the UI or via the API.

Files of interest
- .github/workflows/ci.yml
- .github/workflows/cd.yml
- .github/workflows/destroy.yml
- terraform/ (Terraform code)
- terraform/envs/ (example tfvars per environment for local testing)
- bootstrap/ (optional bootstrap Terraform)
- scripts/setup_github_secrets.sh
- docs/environment_protection.md