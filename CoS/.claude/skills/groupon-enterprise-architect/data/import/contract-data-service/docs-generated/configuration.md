---
service: "contract-data-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secret]
---

# Configuration

## Overview

Contract Data Service is configured through a combination of environment variables and JTier YAML configuration files. The active configuration file is selected via the `JTIER_RUN_CONFIG` environment variable, which points to a per-environment YAML file (e.g., `cloud/staging-us-central1.yml` or `cloud/production-us-central1.yml`). Database credentials and HTTP client secrets are injected as Kubernetes secrets. The `ContractDataServiceConfiguration` class defines the configuration schema: Postgres (RW), Postgres read-only, `dealManagementClient`, and `dealCatalogClient` as top-level YAML keys.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active JTier YAML configuration file | yes | none | env (set by Kubernetes deployment manifest) |

> Staging value: `/var/groupon/jtier/config/cloud/staging-us-central1.yml`
> Production value: `/var/groupon/jtier/config/cloud/production-us-central1.yml`

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase. No feature flag system was identified.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/db/envs/${env}/flyway.properties` | properties | Flyway database migration properties per environment (uses `$[placeholder]` syntax) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Kubernetes deployment config: image, replicas (3), ports (8080/8081), CPU/memory requests |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging overrides: GCP `stable` VPC, `us-central1`, 1–2 replicas, Kafka logging endpoint |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production overrides: GCP `prod` VPC, `us-central1`, 1–6 replicas, Kafka logging endpoint |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Postgres credentials (`postgres` config block) | Read/write database connection credentials | k8s-secret (injected into JTier YAML config at deploy) |
| Postgres read-only credentials (`postgresReadOnly` config block) | Read-only replica connection credentials | k8s-secret |
| `dealManagementClient` credentials | Auth credentials for DMAPI Retrofit client | k8s-secret |
| `dealCatalogClient` credentials | Auth credentials for Deal Catalog Retrofit client | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies. Credentials are stored in `sox-inscope/contract-data-service-secrets` repository (access requires `contract-service-ro` team).

## Per-Environment Overrides

| Setting | Staging | Production |
|---------|---------|------------|
| Cloud provider | GCP | GCP |
| Region | `us-central1` | `us-central1` |
| VPC | `stable` | `prod` |
| Kubernetes namespace | `contract-data-service-staging-sox` | `contract-data-service-production-sox` |
| VIP | `contract-data-service.staging.service.us-central1.gcp.groupondev.com` | `contract-data-service.prod.us-central1.gcp.groupondev.com` |
| Min replicas | 1 | 1 |
| Max replicas | 2 | 6 |
| Memory limit | inherits common (1000Mi) | 2Gi |
| CPU request | inherits common (300m) | 300m |
| Kafka endpoint | `kafka-logging-kafka-bootstrap.kafka-staging.svc.cluster.local` | `kafka-logging-kafka-bootstrap.kafka-production.svc.cluster.local` |
