---
service: "larc"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values, k8s-secrets]
---

# Configuration

## Overview

LARC is configured via a JTier YAML configuration file (`LarcConfiguration`) whose path is injected via the `JTIER_RUN_CONFIG` environment variable at runtime. The configuration file is environment-specific (one per deployment target: `staging-us-central1.yml`, `production-us-central1.yml`). Secrets (FTP credentials, database credentials, service auth tokens) are injected via Kubernetes secrets. Non-secret environment overrides are set in Helm values files under `.meta/deployment/cloud/components/`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the runtime YAML configuration file for the environment | yes | None | helm (env overlay) |
| `ACTIVE_COLO` | Active colocation/datacenter identifier | yes | `snc1` | Dockerfile / env |
| `ACTIVE_ENV` | Active environment name (development, staging, production) | yes | `development` | Dockerfile / env |
| `JTIER_DIR` | Root directory for JTier runtime files | yes | `/var/groupon/jtier` | Dockerfile |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent container OOM from vmem explosion | yes | `4` | helm common.yml |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Disables APM agent TLS certificate verification | no | `false` (production) | helm production overlay |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `nightlyLarArchiveOldQl2Timestamps` | Enables archiving of NightlyLar records with outdated QL2 timestamps | `false` | global |
| `nightlyLarArchivePastNights` | Enables archiving of NightlyLar records for nights already in the past | `false` | global |
| `nightlyLarArchiveUnusedRecords` | Enables archiving of NightlyLar records that are no longer referenced by any active rate plan | `false` | global |

All feature flags are defined in `FeatureFlags` (Java class at `configuration/FeatureFlags.java`) and loaded from the YAML configuration. Defaults are all `false` (conservative: archive is disabled by default).

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Helm values for the `app` component (scaling, ports, log config, resource requests) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production-specific overrides for the `app` component (region, APM endpoint, resource limits) |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging-specific overrides for the `app` component |
| `.meta/deployment/cloud/components/worker/common.yml` | YAML | Helm values for the `worker` component (single replica, no HTTP port) |
| `.meta/deployment/cloud/components/worker/production-us-central1.yml` | YAML | Production-specific overrides for the `worker` component |
| `.meta/deployment/cloud/components/worker-bulk/common.yml` | YAML | Helm values for the `worker-bulk` component (high CPU: 1500m request) |
| `doc/schema.yml` | OpenAPI 3.0 YAML | API schema definition for the LARC REST API |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `ql2FTPConfig.ftpCredentials` | Per-site FTP/SFTP username and password for connecting to QL2 feed servers | k8s-secret |
| `mysql` (DSN / credentials) | MySQL database connection credentials (host, port, username, password, database name) | k8s-secret (via DaaS) |
| `olympiaAuthToken` | Auth token for Olympia-based service-to-service authentication | k8s-secret |
| `inventoryServiceConfig.defaultHeaders` | Auth headers sent to the Travel Inventory Service | k8s-secret |
| `contentServiceConfig.defaultHeaders` | Auth headers sent to the Deal Catalog / Content Service | k8s-secret |
| `rocketmanServiceConfig` | Connection details for the Rocketman email notification service | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies are listed.

## Per-Environment Overrides

- **Staging**: Uses `staging-us-central1.yml` overlays for each component. Kubernetes cluster `gcp-stable-us-central1`, namespace `larc-staging`. Replica counts match production minimums but may be lower. APM enabled.
- **Production**: Uses `production-us-central1.yml` overlays. Kubernetes cluster `gcp-production-us-central1`, namespace `larc-production`. App component: `minReplicas: 2`, `maxReplicas: 15`, memory limit `4000Mi`, CPU request `80m`. APM endpoint pointed at the production Elastic APM cluster.
- **Worker / Worker-Bulk**: Both run as single-replica deployments (`minReplicas: 1`, `maxReplicas: 1`) because they coordinate FTP download state via the MySQL database rather than being horizontally scalable. Worker-Bulk has a significantly higher CPU request (`1500m`) due to bulk CSV processing workload.

## Key Configuration Fields (LarcConfiguration)

| Config Field | Type | Purpose |
|--------------|------|---------|
| `olympiaAuthToken` | String | Olympia service auth token |
| `mysql` | MySQLConfig | Database connection settings |
| `ql2FTPConfig` | QL2FTPConfig | QL2 FTP server credentials and global FTP settings |
| `featureFlags` | FeatureFlags | Archive behavior feature toggles |
| `workerConfig` | WorkerConfig | Standard worker scheduler intervals and settings |
| `workerBulkConfig` | WorkerBulkConfig | Bulk worker scheduler intervals and settings |
| `inventoryServiceConfig` | InventoryServiceConfig | Inventory Service base URL and client settings |
| `contentServiceConfig` | ContentServiceConfig | Content Service base URL and client settings |
| `rocketmanServiceConfig` | RocketmanServiceConfig | Rocketman notification service settings |
| `forceActive` | Boolean | Overrides active/inactive state of workers |
| `bypassGConfig` | Boolean | Bypasses GConfig remote configuration |
| `downloadThreshold` | Integer | Max number of files to download per cycle |
| `ingestionThreshold` | Integer | Max number of ingestion jobs per cycle |
| `larUpdateThreshold` | Integer | Max number of LAR updates to send per cycle |
