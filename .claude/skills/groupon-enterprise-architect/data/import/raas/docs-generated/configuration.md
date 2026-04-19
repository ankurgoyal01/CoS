---
service: "raas"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, github-secrets, kubernetes-configmap]
---

# Configuration

## Overview

RaaS containers are configured through environment variables injected at runtime, with API credentials bootstrapped from GitHub Secrets at startup by the API Caching Service. The K8s Config Updater (`continuumRaasConfigUpdaterService`) uses in-cluster Kubernetes service account credentials. Terraform and Ansible tools receive configuration through playbook variables and Terraform outputs.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | MySQL connection string for RaaS metadata | yes | none | env |
| `POSTGRES_URL` | PostgreSQL connection string for monitoring metadata mirror | yes | none | env |
| `REDISLABS_API_URL` | Base URL for the Redislabs Control Plane API | yes | none | env |
| `REDISLABS_API_KEY` | API key for authenticating to the Redislabs Control Plane | yes | none | github-secrets (bootstrapped at startup) |
| `AWS_REGION` | AWS region for ElastiCache API calls | yes | none | env |
| `KUBECONFIG` / in-cluster | Kubernetes API credentials for config map updates | yes | in-cluster service account | kubernetes |
| `TERRAFORM_DEFS_URL` | URL to Terraform Redis definitions file for resque namespace parsing | yes | none | env |
| `RAILS_ENV` | Rails environment for Info Service | yes | `production` | env |
| `SECRET_KEY_BASE` | Rails secret key base for session signing | yes | none | env / vault |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found for feature flags in the architecture model.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `api_cache/` directory | JSON (filesystem) | Stores atomic API telemetry snapshots written by the API Cache Collector |
| `raas_info/` directory | JSON (filesystem) | Stores rladmin and aggregated status snapshots |
| Kubernetes ConfigMap (telegraf) | YAML | Telegraf deployment configuration updated by `continuumRaasConfigUpdaterService` |
| Terraform output files | HCL/JSON | Consumed by `continuumRaasTerraformAfterhookService_raasTerraformDiffProcessor` for post-deploy reporting |
| Ansible playbook variables | YAML | Input variables for `continuumRaasAnsibleAdminService` create/clone playbooks |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `REDISLABS_API_KEY` | Authenticates API Caching Service and Ansible Admin to the Redislabs Control Plane | github-secrets (read via HTTPS at startup) |
| `SECRET_KEY_BASE` | Rails session signing secret for Info Service | env / vault |
| AWS IAM credentials | Authorize ElastiCache API calls and Kubernetes service account access | aws-iam / k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

> Specific per-environment overrides (dev, staging, production) are not documented in the architecture model. Environment separation is expected to be managed through Kubernetes namespace-scoped secrets and environment-specific Terraform workspaces. Consult the raas-team (raas-team@groupon.com) for environment-specific configuration details.
