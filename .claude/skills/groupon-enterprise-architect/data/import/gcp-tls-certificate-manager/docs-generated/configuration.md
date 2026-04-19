---
service: "gcp-tls-certificate-manager"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "deploy-bot-yml", "request-json-files"]
---

# Configuration

## Overview

This service is configured through three sources: environment variables injected by DeployBot at deployment time (defined in `.deploy_bot.yml`), the `.deploy_bot.yml` file itself (which defines deployment targets, cluster contexts, and image versions), and the JSON request files in `requests/` (which constitute the per-service declarative configuration for certificate provisioning). There is no application server runtime configuration — all configuration is consumed during pipeline or deploybot script execution.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `CERTIFICATE_REFRESH` | Controls whether the deploybot script runs in full-refresh mode (`1`) or change-only mode (`0`) | yes | `0` (for new/updated deploys); `1` (for refresh targets) | `.deploy_bot.yml` per-target `environment_vars` |
| `KUBERNETES_NAMESPACE` | Kubernetes namespace in Conveyor Cloud where cert-manager resources are applied | yes | None | `.deploy_bot.yml` per-target `environment_vars` |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `CERTIFICATE_REFRESH` | When set to `1`, the deploybot image processes all request files for renewal rather than only changed files | `0` | per-deployment-target |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.deploy_bot.yml` | YAML | Defines all DeployBot deployment targets (environments, Kubernetes clusters, promotion paths, image version, Slack notifications, env vars) |
| `Jenkinsfile` | Groovy DSL | Defines the Jenkins pipeline: cron schedule, change detection logic, stage conditions, and deploybotDeploy invocations |
| `requests/**/*.json` | JSON | Per-service declarative certificate request files; define org, service, environments, GCP project IDs, accessors, and optional legacy cert mode |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `tls-certificate-cicd-sa-key` | GCP service account JSON key used by the deploybot image to authenticate against GCP APIs in each environment | Kubernetes Secret (Conveyor Cloud namespace `gcp-tls-certificate-manager-{env}`) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The `.deploy_bot.yml` file defines six deployment targets that differ by environment, Kubernetes cluster, and `CERTIFICATE_REFRESH` mode:

| Target | Environment | Kubernetes Cluster | `CERTIFICATE_REFRESH` | Promotion Path | Manual Approval |
|--------|-------------|-------------------|----------------------|----------------|-----------------|
| `dev-gcp` | dev | `gcp-stable-us-central1` | `0` | `staging-gcp` | no |
| `staging-gcp` | staging | `gcp-stable-us-central1` | `0` | `production-gcp` | no |
| `production-gcp` | production | `gcp-production-us-central1` | `0` | — | yes |
| `dev-gcp-refresh` | dev | `gcp-stable-us-central1` | `1` | `staging-gcp-refresh` | no |
| `staging-gcp-refresh` | staging | `gcp-stable-us-central1` | `1` | `production-gcp-refresh` | no |
| `production-gcp-refresh` | production | `gcp-production-us-central1` | `1` | — | yes |

- **dev and staging**: Kubernetes namespace is `gcp-tls-certificate-manager-{env}` on the `gcp-stable-us-central1` cluster.
- **production**: Kubernetes namespace is `gcp-tls-certificate-manager-production` on the `gcp-production-us-central1` cluster; requires manual approval.
- **Availability zone**: All targets use `us-west-2` (default) except GCP targets which use `us-central1`.
- **DeployBot image**: All targets use `docker.groupondev.com/dnd_gcp_migration_infra/gcp_tls_certificate_manager_deploybot:1.8-test-legacy`.
- **Deployment freeze**: During Groupon Moratoriums, no new deployments or certificate refreshes are permitted without VP approval.
