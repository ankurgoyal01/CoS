---
service: "pricing-control-center-jtier"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secrets]
---

# Configuration

## Overview

The service is configured via YAML config files selected at startup. In development, `development.yml` (which is a symlink to `src/main/resources/config/development.yml`) is used. In cloud environments, the active config file is specified via the `JTIER_RUN_CONFIG` environment variable pointing to an environment-specific YAML (e.g., `/var/groupon/jtier/config/cloud/production-us-central1.yml`). JVM heap size is set via the `HEAP_SIZE` environment variable. Secrets (Hive passwords, GCP private keys, Teradata passwords) are injected into the config file at deploy time and are never committed in plaintext.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active YAML config file for cloud environments | yes (cloud) | None (local uses `development.yml`) | helm/deployment |
| `HEAP_SIZE` | JVM heap size for the container | yes | `4g` (common), `5g` (production) | helm values |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent vmem explosion | yes | `4` | helm values |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `jobConfiguration.sellout.enabled` | Enables or disables `SelloutProgramCreatorJob` execution | `true` (staging), configurable | per-environment |
| `jobConfiguration.rpo.enabled` | Enables or disables `RetailPriceOptimizationJob` execution | `false` (staging) | per-environment |
| `authentication.authenticate` | Enables/disables Doorman token authentication enforcement | `false` (dev), `true` (prod) | per-environment |
| `gcp.enabled` | Enables GCP SDK integration | `true` | per-environment |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development configuration; referenced by `development.yml` symlink |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Kubernetes deployment config (image, ports, logging, base resources) |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging-specific overrides (namespace, replicas, resources) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production-specific overrides (namespace, replicas, heap, resources) |
| `.meta/deployment/cloud/components/app/dev-us-central1.yml` | YAML | Dev environment-specific overrides |
| `doc/swagger/config.yml` | YAML | Swagger UI configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `postgres.app.pass` / `postgres.dba.pass` | PostgreSQL application and DBA credentials | k8s-secret (injected at deploy) |
| `hive.user` / `hiveGcp.user` + passwords | Hive service account credentials for on-prem and GCP gateway | k8s-secret |
| `gcpConfiguration.privateKey` / `gcpConfiguration.privateKeyId` | GCP service account private key for GCS access | k8s-secret |
| Teradata password (`ub_dp_eng_non_prod` / `ub_dpeng`) | Credentials for Teradata external analytics log raw access | k8s-secret (rotated via grit.groupondev.com tool) |
| `clients.usersServiceClient.authenticationOptions.value` | x-api-key for Users Service | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

### Development (local)

- PostgreSQL at `127.0.0.1:5432` (Docker container `jtier-daas-postgres-testing:0.7.0`)
- Pricing Service client points to `http://pricing-app-staging-vip.snc1`
- VIS client points to `http://voucher-inventory-staging.snc1`
- Users Service client points to `https://users-service-app-staging-vip.snc1`
- Gdoop client at `http://gdoop-namenode-vip.snc1:50070`
- Hive at `jdbc:hive2://cerebro-hive-server3.snc1:10000`
- Authentication disabled (`authenticate: false`)
- Sellout job enabled; RPO job disabled
- JVM heap: 4g, threads: 50 max / 8 min
- Quartz thread pool: 2 threads

### Staging (GCP us-central1)

- Kubernetes namespace: `pricing-control-center-jtier-staging-sox`
- Config: `/var/groupon/jtier/config/cloud/staging-us-central1.yml`
- Replicas: 1 min, 5 max
- CPU: 650m request; Memory: 4 Gi request / 6 Gi limit
- GCP cluster: `gcp-stable-us-central1`

### Production (GCP us-central1)

- Kubernetes namespace: `pricing-control-center-jtier-production-sox`
- Config: `/var/groupon/jtier/config/cloud/production-us-central1.yml`
- Replicas: 6 min, 10 max
- CPU: 750m request; Memory: 6 Gi request / 8 Gi limit
- Heap: 5g
- GCP cluster: `gcp-production-us-central1`
- SOX compliance enforced; Doorman authentication active

## ILS Channel Validation Configuration

The `ilsConf` block in the YAML config drives per-channel business rules used by validators:

| Channel Key | Max File Size | Lead Time (hrs) | Min Duration (hrs) | Max Duration (hrs) | Max Discount | Min Margin |
|-------------|--------------|-----------------|-------------------|-------------------|-------------|-----------|
| `goodsEmea` | 30,000 rows | 24 | 1 | 672 (28 days) | 90% | -1000 |
| `goodsNa` | 30,000 rows | 24 | 1 | 1488 (62 days) | 80% | -75 |
| `localEmea` | 30,000 rows | 24 | 1 | 672 (28 days) | 50% | 0 |
| `localNa` | 30,000 rows | 24 | 1 | 1488 (62 days) | 80% | -75 |
| `rpoNa` | 30,000 rows | 24 | 1 | 1488 (62 days) | 10% | -75 |
| `customNa` | N/A | 8 | 24 | 1488 (62 days) | N/A | N/A |
| `sellout` | N/A | 1 | N/A | N/A | N/A | N/A |
