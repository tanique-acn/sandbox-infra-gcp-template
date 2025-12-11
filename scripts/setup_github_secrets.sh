#!/usr/bin/env bash
# Extended setup script that creates per-environment repository secrets for:
#  - GCP_SA_KEY_DEV / GCP_SA_KEY_QA / GCP_SA_KEY_UAT / GCP_SA_KEY_PRODUCTION
#  - GCP_PROJECT_DEV / GCP_PROJECT_QA / GCP_PROJECT_UAT / GCP_PROJECT_PRODUCTION
# It also sets fallback repository-level secrets: GCP_SA_KEY and GCP_PROJECT.
#
# Usage:
#   ./scripts/setup_github_secrets.sh \
#     --sa-key-path ./gcp-sa.json \
#     --project global-fallback-project \
#     --project-dev dev-project-id \
#     --project-qa qa-project-id \
#     --project-uat uat-project-id \
#     --project-prod prod-project-id \
#     --region us-central1 \
#     --zone us-central1-a \
#     --tf-bucket my-tf-state-bucket \
#     --tf-prefix terraform/state \
#     [--repo owner/repo] \
#     [--env-sa-keys-dir ./env-keys]
#
# If --env-sa-keys-dir contains dev.json, qa.json, uat.json, production.json those will be uploaded
# as GCP_SA_KEY_DEV, etc. If not provided, the main --sa-key-path will be used for all envs.

set -euo pipefail

print_usage() {
  cat <<EOF
Usage: $0 --sa-key-path PATH --project PROJECT \
  --project-dev PROJECT_DEV --project-qa PROJECT_QA --project-uat PROJECT_UAT --project-prod PROJECT_PROD \
  --region REGION --zone ZONE --tf-bucket BUCKET --tf-prefix PREFIX [--repo owner/repo] [--env-sa-keys-dir DIR]
EOF
}

# parse args
REPO=""
SA_KEY_PATH=""
PROJECT=""
PROJECT_DEV=""
PROJECT_QA=""
PROJECT_UAT=""
PROJECT_PROD=""
REGION=""
ZONE=""
TF_BUCKET=""
TF_PREFIX=""
ENV_SA_KEYS_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2;;
    --sa-key-path) SA_KEY_PATH="$2"; shift 2;;
    --project) PROJECT="$2"; shift 2;;
    --project-dev) PROJECT_DEV="$2"; shift 2;;
    --project-qa) PROJECT_QA="$2"; shift 2;;
    --project-uat) PROJECT_UAT="$2"; shift 2;;
    --project-prod) PROJECT_PROD="$2"; shift 2;;
    --region) REGION="$2"; shift 2;;
    --zone) ZONE="$2"; shift 2;;
    --tf-bucket) TF_BUCKET="$2"; shift 2;;
    --tf-prefix) TF_PREFIX="$2"; shift 2;;
    --env-sa-keys-dir) ENV_SA_KEYS_DIR="$2"; shift 2;;
    -h|--help) print_usage; exit 0;;
    *) echo "Unknown arg: $1"; print_usage; exit 1;;
  esac
done

if [[ -z "$SA_KEY_PATH" || -z "$PROJECT" || -z "$PROJECT_DEV" || -z "$PROJECT_QA" || -z "$PROJECT_UAT" || -z "$PROJECT_PROD" || -z "$REGION" || -z "$ZONE" || -z "$TF_BUCKET" || -z "$TF_PREFIX" ]]; then
  echo "Missing required argument(s)."
  print_usage
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh (GitHub CLI) not found. Install and authenticate (https://cli.github.com/)."
  exit 1
fi

if [[ ! -f "$SA_KEY_PATH" ]]; then
  echo "Service account key file not found at $SA_KEY_PATH"
  exit 1
fi

if [[ -z "$REPO" ]]; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner) || {
    echo "Failed to detect repository. Provide --repo owner/repo"
    exit 1
  }
fi

echo "Using repository: $REPO"

SA_KEY_CONTENT=$(cat "$SA_KEY_PATH")

set_repo_secret() {
  local name="$1"
  local body="$2"
  echo "-> Setting repository secret $name"
  gh secret set "$name" --body "$body" --repo "$REPO"
}

# Set fallback/global repo secrets
set_repo_secret "GCP_SA_KEY" "$SA_KEY_CONTENT"
set_repo_secret "GCP_PROJECT" "$PROJECT"
set_repo_secret "GCP_REGION" "$REGION"
set_repo_secret "GCP_ZONE" "$ZONE"
set_repo_secret "TF_STATE_BUCKET" "$TF_BUCKET"
set_repo_secret "TF_STATE_PREFIX" "$TF_PREFIX"

# Set per-environment project ids
set_repo_secret "GCP_PROJECT_DEV" "$PROJECT_DEV"
set_repo_secret "GCP_PROJECT_QA" "$PROJECT_QA"
set_repo_secret "GCP_PROJECT_UAT" "$PROJECT_UAT"
set_repo_secret "GCP_PROJECT_PRODUCTION" "$PROJECT_PROD"

# Create environment placeholders
ENVIRONMENTS=("dev" "qa" "uat" "production")
for env in "${ENVIRONMENTS[@]}"; do
  echo "Creating environment: $env (if not exists)"
  gh api --method PUT "/repos/${REPO}/environments/${env}" -f protection_rules='[]' >/dev/null 2>&1 || true
done

# Create per-environment SA secrets (use per-env key files if supplied)
for env in "${ENVIRONMENTS[@]}"; do
  env_upper=$(echo "$env" | tr '[:lower:]' '[:upper:]')
  candidate_key="$ENV_SA_KEYS_DIR/${env}.json"
  secret_name="GCP_SA_KEY_${env_upper}"

  if [[ -n "$ENV_SA_KEYS_DIR" && -f "$candidate_key" ]]; then
    echo "-> Using environment-specific key for $env from $candidate_key"
    key_content=$(cat "$candidate_key")
  else
    echo "-> Using main SA key for environment $env"
    key_content="$SA_KEY_CONTENT"
  fi

  set_repo_secret "$secret_name" "$key_content"
done

cat <<EOF

Done. Created:
- Repository-level fallback secrets: GCP_SA_KEY, GCP_PROJECT, GCP_REGION, GCP_ZONE, TF_STATE_BUCKET, TF_STATE_PREFIX
- Per-environment project secrets: GCP_PROJECT_DEV, GCP_PROJECT_QA, GCP_PROJECT_UAT, GCP_PROJECT_PRODUCTION
- Per-environment SA key secrets: GCP_SA_KEY_DEV, GCP_SA_KEY_QA, GCP_SA_KEY_UAT, GCP_SA_KEY_PRODUCTION

Next steps:
1. Configure environment protection rules for UAT and production in repository Settings → Environments.
2. Optionally create environment-scoped secrets via the UI if you prefer environment-level secrets instead of repo-level per-environment secrets.
3. Test by pushing to dev/qa/uat/main branches to verify jobs use the correct per-environment project.

EOF