---
service: "releasegen"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values, k8s-secrets]
---

# Configuration

## Overview

Releasegen is configured through a combination of environment variables and per-environment JTier YAML config files. The active config file path is injected via the `JTIER_RUN_CONFIG` environment variable, which points to a mounted Kubernetes secret volume file. The config file contains four top-level blocks: `deploybot`, `jira`, `github`, and `worker`. Secrets (GitHub private key, API credentials) are mounted from Kubernetes secrets by the Helm chart and referenced only as file paths or environment variable names.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the active JTier YAML config file for this environment | yes | none | helm (env-specific override) |
| `APP_PRIVATE_KEY` | GitHub App RSA private key for JWT signing | yes (App auth mode) | none | k8s-secret (mounted via `.envrc`) |
| `APPLICATION_ID` | GitHub App installation ID | yes (App auth mode) | none | k8s-secret (mounted via `.envrc`) |
| `GITHUB_ENDPOINT` | GitHub Enterprise base URL | yes | none | k8s-secret / env |
| `GITHUB_TOKEN` | GitHub personal access token (alternative to App auth for local development) | no | none | env / `.github_access_token` file |
| `MALLOC_ARENA_MAX` | Tunes glibc malloc arenas to prevent virtual memory explosion in containers | no | `4` | helm (common.yml) |
| `DEPLOYCAP_BUNDLE_ARGS` | Arguments passed to the deployment bundle script | no | `--path .bundle` | deploybot config |

> IMPORTANT: Secret values are never documented here. Only variable names and purposes are listed.

## Feature Flags

> No evidence found in codebase. No feature flag system is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Base Kubernetes deployment config: image, scaling (2–15 replicas), ports (8080 HTTP, 8081 admin, 8009 JMX), CPU (1000m) and memory (500Mi) requests |
| `.meta/deployment/cloud/components/app/production-us-west-1.yml` | YAML | Production AWS us-west-1 overrides: `JTIER_RUN_CONFIG` path, filebeat volume type |
| `.meta/deployment/cloud/components/app/production-us-west-2.yml` | YAML | Production AWS us-west-2 overrides |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production AWS eu-west-1 overrides |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production GCP us-central1 overrides |
| `.meta/deployment/cloud/components/app/staging-us-west-1.yml` | YAML | Staging AWS us-west-1 overrides (1–2 replicas) |
| `.meta/deployment/cloud/components/app/staging-us-west-2.yml` | YAML | Staging AWS us-west-2 overrides |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging GCP us-central1 overrides |
| `.meta/deployment/cloud/components/app/rde-dev-us-west-2.yml` | YAML | RDE dev overrides (1 replica) |
| `.meta/deployment/cloud/components/app/rde-staging-us-west-2.yml` | YAML | RDE staging overrides |
| `.deploy_bot.yml` | YAML | Deploybot deployment target definitions with promote-to chains |
| `Jenkinsfile` | Groovy | CI pipeline using `java-pipeline-dsl@latest-2`; deploy targets `staging-us-west-1` and `staging-us-central1` |
| `doc/swagger/config.yml` | YAML | Swagger UI configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `.meta/deployment/cloud/secrets/groupon.env` | Contains `APP_PRIVATE_KEY`, `APPLICATION_ID`, `GITHUB_ENDPOINT` for GitHub App auth | k8s-secret (mounted file) |
| `.meta/deployment/cloud/secrets/cloud/<env>.yml` | Per-environment secrets for Deploybot, GitHub, and JIRA credentials | k8s-secret (mounted file, passed to Helm) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Production** (all regions): `minReplicas=2`, `maxReplicas=15`, `filebeat.volumeType=medium`, `JTIER_RUN_CONFIG` points to the production config file
- **Staging**: `minReplicas=1`, `maxReplicas=2`, `filebeat.volumeType=low`, `JTIER_RUN_CONFIG` points to the staging config file
- **RDE dev**: `minReplicas=1`, `maxReplicas=1`, `filebeat.volumeType=low`
- Worker auto-start (`worker.autoStart`) defaults to `true`; the worker `pollPeriod` defaults to 1 minute and `initialWindow` defaults to 8 days (configurable in the JTier YAML config file)
