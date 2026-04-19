---
service: "deals-cluster-api-jtier"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values, vault]
---

# Configuration

## Overview

The Deals Cluster API is configured via a combination of per-environment YAML config files (JTier run config), Helm values, and environment variables injected at container startup. The active JTier configuration file is selected via the `JTIER_RUN_CONFIG` environment variable, which points to the environment-specific YAML. Secrets (database credentials, message bus credentials) are managed via Groupon's secrets management (Vault/k8s secrets), injected via `.meta/deployment/cloud/secrets/cloud/` files that are not committed to the repository.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active JTier YAML config file for the current environment | yes | — | Helm values (per-environment override) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase of explicit feature flag configuration.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development JTier configuration (database, message bus, server ports) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Helm values for the API app component (image, ports, scaling, logging) |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging overrides for US-central1 (replicas 1-2, JTIER_RUN_CONFIG path) |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging overrides for europe-west1 |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production overrides for US-central1 (replicas 4-10, CPU 2000m, memory 5-6Gi) |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | Production overrides for europe-west1 (replicas 2-10, CPU 2000m, memory 3.3-4Gi) |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production overrides for AWS eu-west-1 |
| `.meta/deployment/cloud/components/worker/common.yml` | YAML | Common Helm values for the worker component (image, ports, memory 2-3Gi) |
| `.meta/deployment/cloud/components/worker/staging-us-central1.yml` | YAML | Staging worker overrides for US-central1 |
| `.meta/deployment/cloud/components/worker/staging-europe-west1.yml` | YAML | Staging worker overrides for europe-west1 |
| `.meta/deployment/cloud/components/worker/production-us-central1.yml` | YAML | Production worker overrides for US-central1 |
| `doc/swagger/config.yml` | YAML | Swagger UI configuration |
| `.mvn/maven.config` | Text | Maven build flags (`-U --fail-at-end`) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `.meta/deployment/cloud/secrets/cloud/<env>.yml` | Per-environment secrets (DB credentials, message bus credentials, auth keys) | Vault / k8s-secret (files not committed to repo) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Staging (us-central1) | Staging (europe-west1) | Production (us-central1) | Production (europe-west1) |
|---------|----------------------|------------------------|--------------------------|---------------------------|
| `JTIER_RUN_CONFIG` | `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | (similar pattern) | `/var/groupon/jtier/config/cloud/production-us-central1.yml` | `/var/groupon/jtier/config/cloud/production-eu-west-1.yml` |
| `minReplicas` (app) | 1 | — | 4 | 2 |
| `maxReplicas` (app) | 2 | — | 10 | 10 |
| CPU request (app) | — (default 50m) | — | 2000m | 2000m |
| Memory request (app) | — (default 1Gi) | — | 5Gi | 3300Mi |
| Memory limit (app) | — (default 2Gi) | — | 6Gi | 4Gi |
| `cloudProvider` | gcp | gcp | gcp | gcp |
| `vpc` | stable | stable | prod | prod |
| Namespace | `deals-cluster-staging` | `deals-cluster-staging` | `deals-cluster-production` | `deals-cluster-production` |
| Filebeat Kafka env | staging | staging | production | production |
