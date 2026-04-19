---
service: "deletion_service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secrets]
---

# Configuration

## Overview

The Deletion Service is configured through a combination of environment variables and YAML configuration files that are injected at runtime. The active configuration file is selected via the `JTIER_RUN_CONFIG` environment variable, which points to a region- and environment-specific YAML file bundled inside the container (e.g. `production-us-central1.yml` or `production-eu-west-1.yml`). Secrets such as database credentials are expected to be provided via Kubernetes secrets mounted into the JTier config system (DaaS secrets). Non-secret deployment tunables are defined in the Raptor deployment YAMLs under `.meta/deployment/cloud/components/deletion-service-component/`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active YAML config file inside the container | Yes | None | Kubernetes deployment YAML (env-var) |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent excessive virtual memory growth | No | `4` | `.meta/deployment/cloud/components/deletion-service-component/common.yml` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `flags.runMBusWorker` | Enables or disables the MBUS consumer workers (both default and SMS consent topics) | Not documented (must be set in config file) | per-instance |
| `flags.runJobScheduler` | Enables or disables the Quartz scheduler for the 30-minute erase retry job | Not documented (must be set in config file) | per-instance |

Both flags are read from the `FlagsConfig` block in the application YAML configuration file.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` (referenced via symlink `development.yml`) | YAML | Local development configuration |
| `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | YAML | Staging (GCP us-central1) runtime configuration |
| `/var/groupon/jtier/config/cloud/production-us-central1.yml` | YAML | Production NA (GCP us-central1) runtime configuration |
| `/var/groupon/jtier/config/cloud/production-eu-west-1.yml` | YAML | Production EMEA (AWS eu-west-1) runtime configuration |
| `doc/swagger/config.yml` | YAML | Swagger UI configuration for the OpenAPI spec |

The YAML config files contain all structured configuration blocks described below. They are bundled into the container image or mounted at deploy time.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `postgres` (DaaS config) | Deletion Service PostgreSQL connection credentials | JTier DaaS / k8s-secret |
| `ordersMySQL` (DaaS config) | Orders MySQL connection credentials | JTier DaaS / k8s-secret |
| `ciPostgres` (DaaS config) | Commerce Interface PostgreSQL credentials (disabled integration) | JTier DaaS / k8s-secret |
| `gisPostgres` (DaaS config) | Goods Inventory Service PostgreSQL credentials (disabled integration) | JTier DaaS / k8s-secret |
| `srsMySQL` (DaaS config) | Smart Routing MySQL credentials (disabled integration) | JTier DaaS / k8s-secret |
| `messageBus` credentials | MBUS broker credentials for the default erase topic | JTier MBUS config / k8s-secret |
| `smsConsentMessageBus` credentials | MBUS broker credentials for the SMS consent erasure topic | JTier MBUS config / k8s-secret |
| `rocketmanServiceClient` credentials | HTTP client credentials for the Rocketman transactional API | JTier Retrofit config / k8s-secret |
| `clientIds` | Client-ID role map for admin API authentication | JTier auth bundle / k8s-secret |
| AWS `accessKey` / `secretKey` | AWS credentials for S3 access (configured but not in active use) | `AwsConfigExtension` / k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Config Block | Staging (us-central1) | Production NA (us-central1) | Production EMEA (eu-west-1) |
|---|---|---|---|
| `JTIER_RUN_CONFIG` | `staging-us-central1.yml` | `production-us-central1.yml` | `production-eu-west-1.yml` |
| `cloudProvider` | `gcp` | `gcp` | `aws` |
| `vpc` | `stable` | `prod` | `prod` |
| `minReplicas` | `1` | `1` | `1` |
| `maxReplicas` | `2` | `3` | `3` |
| `isEmea` | `false` (inferred) | `false` | `true` |

The `isEmea` flag in the application YAML changes which `EraseServiceType` entries are active:
- NA: `DEFAULT` option activates `ORDERS`; `ATTENTIVE` option activates `SMS_CONSENT_SERVICE`
- EMEA: `DEFAULT` option activates `ORDERS`; `ATTENTIVE` option activates no services (empty list)

The `eraseRequestMaxRetries` configuration key controls how many times a failed erase request is retried by the scheduler (default: `3`).
