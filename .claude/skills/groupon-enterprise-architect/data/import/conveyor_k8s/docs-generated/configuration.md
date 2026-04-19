---
service: "conveyor_k8s"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, github-actions-vars, github-actions-secrets, vault, helm-values]
---

# Configuration

## Overview

Conveyor K8s is configured through a combination of GitHub Actions repository variables, GitHub Actions secrets, Ansible Vault-encrypted secrets, and environment variables passed into pipeline containers. Jenkins pipelines receive configuration through build parameters (interactive choices at job trigger time). The Go utility binaries use environment variables (via `kelseyhightower/envconfig`) and CLI flags.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENVIRONMENT` | Target environment name (dev, stable, production) | yes | — | GitHub Actions repo vars |
| `GCP_REGION` | GCP region for Ansible inventory and cluster targeting | yes | — | GitHub Actions repo vars (`GCP_REGION_US`, `GCP_REGION_EU`) |
| `GOOGLE_PROJECT` | GCP project ID for the target environment | yes | — | GitHub Actions repo vars (`GCP_PROJECT_ID`) |
| `SHARED_VPC_PROJECT` | GCP Shared VPC project ID | yes | — | GitHub Actions repo vars |
| `GCP_SERVICE_ACCOUNT_JSON` | GCP service account credentials for Terraform and Ansible GCP auth | yes | — | GitHub Actions secret |
| `VAULT_PASSPHRASE` | Passphrase for Ansible Vault-encrypted secrets | yes | — | GitHub Actions secret |
| `GITHUB_TOKEN` | GitHub token for creating releases | yes | — | GitHub Actions built-in secret |
| `DANGER_GITHUB_API_TOKEN` | GitHub API token for Danger PR linting | no | — | Jenkins credential |
| `REGIONS` | Comma-separated AWS regions for AMI lookup | yes | — | env (ami_lookup binary) |
| `SHA` | Git SHA for AMI lookup filtering | yes | — | env (ami_lookup binary) |
| `FAILNOTFOUND` | Whether ami_lookup should exit non-zero when AMI not found | no | `false` | env (ami_lookup binary) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase. Conveyor K8s does not use a feature flag system. Behaviour is controlled by pipeline parameters (e.g., `GENERATE_RELEASE`, `ENABLE_SANDBOX_METRICS`, `RUN_INTEGRATION_TESTS` in Jenkins builds).

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `conveyor_provisioning_playbook/inventory/gcp_grpn.py` | Python | Dynamic Ansible inventory for GCP clusters |
| `terra-eks/cluster_definitions/generic/eks-cluster/data.tf` | Terraform HCL | Cross-module remote state references for EKS cluster definitions |
| `terra-gke/cluster_definitions/generic/gke-cluster/data.tf` | Terraform HCL | Cross-module remote state references for GKE cluster definitions |
| `terra-eks/modules/eks-cluster/variables.tf` | Terraform HCL | EKS cluster input variable definitions (AMI git tag, worker config, IAM roles) |
| `terra-gke/modules/gke-cluster/variables.tf` | Terraform HCL | GKE cluster input variable definitions (kubernetes version, region, project) |
| `.terraform-version` | plain text | Pins Terraform CLI version to `0.14.11` for EKS modules |
| `Makefile` | Makefile | Developer setup, subtree management, formatting commands |
| `.github/actions/detect-playbooks/action.yml` | YAML | Composite action — detects changed Ansible playbooks from PR or tag diff |
| `.github/actions/run-playbooks/action.yml` | YAML | Composite action — runs `ansible-playbook` for each detected playbook |
| `.github/actions/rollback-playbooks/action.yml` | YAML | Composite action — re-runs playbooks from master to rollback dev clusters |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `GCP_SERVICE_ACCOUNT_JSON` | GCP service account key for Terraform and Ansible GCP authentication | GitHub Actions secret |
| `VAULT_PASSPHRASE` | Passphrase for decrypting Ansible Vault-encrypted variables | GitHub Actions secret |
| `GITHUB_TOKEN` | Token for creating GitHub releases | GitHub Actions built-in secret |
| `DANGER_GITHUB_API_TOKEN` | Token for Danger.js PR title linting in Jenkins | Jenkins credential store |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Environments in this repo are: `dev`, `stable`, `production`, and `sandbox`.

- **Dev**: GitHub Actions deploys on pull requests targeting `conveyor_provisioning_playbook/**`. Changes are applied to dev clusters and then automatically rolled back to master after the PR run, ensuring dev clusters remain at a known state. Cluster names read from `GCP_CLUSTER_NAME_US` / `GCP_CLUSTER_NAME_EU` repo vars.
- **Stable**: Deployed on SemVer tag push (`v*.*.*`) via `apply-ansible-playbook-stable.yml`. Targets both US and EU stable clusters in parallel without rollback. Manual approval not required.
- **Production**: Deployed on SemVer tag push (`v*.*.*`) via `apply-ansible-playbook-production.yml`. Requires manual approval (GitHub Actions environment protection rule on `production` environment). Only US production cluster currently has a named cluster entry; EU production is a placeholder.
- **Manual/Rollback**: Triggered via `workflow_dispatch` (`apply-ansible-playbook-manual.yml`). Operator selects environment (dev/stable/production), region (US/EU), a specific git ref (tag or commit), and an explicit playbook name. Designed for emergency rollbacks and hot-fixes.
- **Sandbox**: Cluster cleanup runs as a scheduled Jenkins job (`pipelines/sandbox-cleanup.groovy`). Sandbox clusters are skipped during AMI publish (the original AMIs are generated in the sandbox account).

Terraform environment-specific configuration is managed via `terra-gke/cluster_manifests/override/env/<region>/<environment>.yaml` files. Changes to production and stable override files are excluded from automatic apply after master merge (only applied through explicit tag-triggered workflows).
