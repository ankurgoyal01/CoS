---
service: "tronicon-cms"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values, vault]
---

# Configuration

## Overview

Tronicon CMS is configured via JTier run configuration YAML files selected by the `JTIER_RUN_CONFIG` environment variable, plus Kubernetes Helm values defined in `.meta/deployment/cloud/components/app/`. Secrets (database credentials and APM tokens) are managed in a separate `tronicon-cms-secrets` repository and injected at runtime. The `ELASTIC_APM_VERIFY_SERVER_CERT` environment variable suppresses TLS verification for the cluster-local APM endpoint.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the JTier runtime configuration YAML for the active environment | yes | None | helm (per-environment deployment YAML in `.meta/deployment/cloud/components/app/`) |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Controls whether the Elastic APM Java agent verifies the APM server TLS certificate | no | `"false"` (staging and production environments) | helm (per-environment deployment YAML) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase. No feature flag system is configured.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Kubernetes deployment defaults: image name, HTTP/admin ports (8080/8081), baseline CPU/memory, logging platform (`elk`), APM enabled, Filebeat volume type |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging US (GCP us-central1) overrides: min=1, max=5 replicas, VIP, APM endpoint |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging EMEA (GCP europe-west1) overrides: min=1, max=5 replicas, VIP, APM disabled |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production US (GCP us-central1) overrides: min=2, max=60 replicas, VIP, CPU=1/2, memory=2Gi |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production EMEA (AWS eu-west-1) overrides: min=2, max=50 replicas, VIP, CPU=1/2, memory=2Gi |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | Production EMEA (GCP europe-west1) overrides |
| `.deploy_bot.yml` | YAML | DeployBot deployment targets: Kubernetes cluster names, contexts, promote chains (staging → production) |
| `src/main/resources/config/development.yml` | YAML | Local development JTier run configuration (database URL, server ports) |
| `src/main/resources/db/migration/V*.sql` | SQL | Flyway database schema migration scripts — applied automatically at startup |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Database credentials | MySQL DaaS username and password for the `tronicon_cms_prod` / `tronicon_stg` databases | Vault / Kubernetes secret (managed via `tronicon-cms-secrets` repository) |
| APM credentials | Elastic APM authentication token (if required by the cluster-local endpoint) | Vault / Kubernetes secret (managed via `tronicon-cms-secrets` repository) |

> Secret values are NEVER documented here. Only names and purposes. For rotation procedures see the [Managing Secrets runbook](https://github.groupondev.com/tronicon/tronicon-cms-secrets/blob/main/README.md).

## Per-Environment Overrides

| Setting | Staging (us-central1) | Staging (europe-west1) | Production (us-central1) | Production (eu-west-1) |
|---------|----------------------|------------------------|--------------------------|------------------------|
| `minReplicas` | 1 | 1 | 2 | 2 |
| `maxReplicas` | 5 | 5 | 60 | 50 |
| CPU request (main) | 1 | — | 1 | 1 |
| CPU limit (main) | 2 | — | 2 | 2 |
| Memory request (main) | 2Gi | — | 2Gi | 2Gi |
| Memory limit (main) | 2Gi | — | 2Gi | 2Gi |
| VIP | `tronicon-cms.us-central1.conveyor.stable.gcp.groupondev.com` | `tronicon-cms.europe-west1.conveyor.stable.gcp.groupondev.com` | `tronicon-cms.us-central1.conveyor.prod.gcp.groupondev.com` | `tronicon-cms.prod.eu-west-1.aws.groupondev.com` |
| APM enabled | yes | no | yes | yes |
| `JTIER_RUN_CONFIG` | `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | `/var/groupon/jtier/config/cloud/staging-europe-west1.yml` | `/var/groupon/jtier/config/cloud/production-us-central1.yml` | `/var/groupon/jtier/config/cloud/production-eu-west-1.yml` |

Common settings across all environments:
- HTTP port: `8080`
- Admin port: `8081`
- Logging platform: `elk`
- Steno source type: `tronicon-cms`
- APM TLS verification: disabled (`ELASTIC_APM_VERIFY_SERVER_CERT=false`)
- `hpaTargetUtilization`: `50` (common baseline)
