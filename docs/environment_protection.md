# Example Environment Protection Configuration Notes

This document provides recommended configuration for GitHub Environment protections (dev, qa, uat, production) to align with the repository's CI/CD workflows.

Overview
- The CD workflow includes explicit wait/approval jobs for UAT and production. Those jobs are configured with the environment property (uat / production) and will pause until deployment approval is granted according to the environment protection rules.
- This prevents automatic applies to UAT and production and enforces manual approvals.

Recommended protection per environment

1) dev (low friction)
- Purpose: developer testing
- Protection:
  - Allow GitHub Actions to deploy
  - No required reviewers (optional)
  - Optionally restrict to the `dev` branch

2) qa (moderate protection)
- Purpose: team integration testing
- Protection:
  - Require 1 reviewer (optional)
  - Allow GitHub Actions to deploy
  - Optionally restrict to the `qa` branch

3) uat (manual approval required)
- Purpose: user acceptance testing
- Protection:
  - Require 1–2 reviewers (or specific team) to approve deployments
  - CD workflow contains a dedicated "Await UAT approval" job pointing at the 'uat' environment — configure required reviewers here.
  - Restrict secrets to the 'uat' environment (if using per-environment secrets)

4) production (highest protection — manual approval required)
- Purpose: production changes
- Protection:
  - Require 2+ approvers or release manager/team approval
  - CD workflow contains "Await Production approval" job pointing at the 'production' environment — configure required reviewers here.
  - Restrict who can deploy to the production environment (specific users/teams)
  - Restrict deployments to the `main` branch
  - Use environment-level secrets for production (rotate regularly)

How to configure (UI)
1. Go to repository → Settings → Environments.
2. Create/select environment (dev, qa, uat, production).
3. Add Deployment protection rules:
   - Required reviewers (individuals or teams) for UAT and production.
   - Optionally add wait timers.
   - Restrict deployments to specific branches.
4. Save changes.

How to configure (API / automation)
- Create environment placeholders with:
  PUT /repos/{owner}/{repo}/environments/{environment_name}
- To add protection rules programmatically, use the GitHub REST API endpoints for environment protection (requires a token with admin repo permissions).
- The provided setup script (`scripts/setup_github_secrets.sh`) will create environment placeholders but will NOT set reviewer rules automatically — you can extend the script to configure protection via the API if desired.

Best practices
- Use per-environment GCP projects and per-environment service accounts (the setup script can create repository secrets for each environment).
- Use environment-level secrets for production if you want them restricted to that environment.
- Keep the list of approvers for UAT/production small and well-audited.
- Rotate service account keys and prefer short-lived credentials where possible.
- Test the approval flow by pushing to `uat` and `main` and confirming the workflow pauses at the "Await ... approval" job.