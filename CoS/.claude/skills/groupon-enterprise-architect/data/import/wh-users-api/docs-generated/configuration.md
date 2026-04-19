---
service: "wh-users-api"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secret]
---

# Configuration

## Overview

wh-users-api is configured via a combination of environment variables and YAML configuration files mounted into the container at runtime. The JTier framework reads the YAML file path from the `JTIER_RUN_CONFIG` environment variable. Secrets (database credentials) are stored in a separate `wh-users-api-secrets` repository and injected as Kubernetes secrets at deploy time via Helm. Per-environment overrides are managed in `.meta/deployment/cloud/components/api/<env>-<region>.yml`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the JTier YAML config file for the current environment and region | yes | none | env (per-environment deployment config) |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Disables SSL certificate verification for the Elastic APM endpoint | no | `"false"` (in staging/production) | env (deployment config) |
| `JMX_HOST` | JMX bind address for monitoring | no | `"127.0.0.1"` | env (common deployment config) |
| `MALLOC_ARENA_MAX` | Limits glibc malloc arena count to reduce native memory fragmentation | no | `4` | env (common deployment config) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase.

No feature flags or runtime toggles are configured in this service.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/api/common.yml` | YAML | Base Kubernetes deployment config — scaling, ports, logging, memory/CPU defaults |
| `.meta/deployment/cloud/components/api/production-us-central1.yml` | YAML | Production US (GCP us-central1) overrides — namespace, replicas, VIP, APM endpoint, resource limits |
| `.meta/deployment/cloud/components/api/production-eu-west-1.yml` | YAML | Production EMEA (AWS eu-west-1) overrides — namespace, replicas, resource limits |
| `.meta/deployment/cloud/components/api/production-europe-west1.yml` | YAML | Production EMEA (GCP europe-west1) overrides |
| `.meta/deployment/cloud/components/api/staging-us-central1.yml` | YAML | Staging US (GCP us-central1) overrides — namespace, replicas, VIP, APM endpoint |
| `.meta/deployment/cloud/components/api/staging-europe-west1.yml` | YAML | Staging EMEA (GCP europe-west1) overrides |
| `doc/swagger/config.yml` | YAML | Swagger UI configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| PostgreSQL RW credentials | Database username and password for the read-write primary (app user and DBA user) | k8s-secret (sourced from `wh-users-api-secrets` repository, mounted via Helm at deploy time) |
| PostgreSQL RO credentials | Database username and password for the read-only replica | k8s-secret (sourced from `wh-users-api-secrets` repository) |

> Secret values are NEVER documented. Only names and rotation policies are listed here. See `docs/runbooks/How_to_work_with_secret_repository.md` for secret management procedures.

## Per-Environment Overrides

| Setting | Staging (us-central1) | Production (us-central1) | Production (eu-west-1) |
|---------|----------------------|--------------------------|------------------------|
| `namespace` | `wh-users-api-staging` | `wh-users-api-production` | `wh-users-api-production` |
| `minReplicas` | 1 | 1 | 1 |
| `maxReplicas` | 2 | 3 | 3 |
| `memory.main.request` | 1.1Gi | 1.1Gi | 1.1Gi |
| `memory.main.limit` | 2.5Gi | 2.5Gi | 2.5Gi |
| `cpus.main.request` | (common default: 50m) | 100m | 100m |
| `filebeat.volumeType` | `low` | `high` | `high` |
| `JTIER_RUN_CONFIG` | `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | `/var/groupon/jtier/config/cloud/production-us-central1.yml` | `/var/groupon/jtier/config/cloud/production-eu-west-1.yml` |
| APM endpoint | Elastic APM (stable cluster) | Elastic APM (prod cluster) | Not explicitly set |

### Ports (common)

| Port | Purpose |
|------|---------|
| `8080` | HTTP application traffic |
| `8081` | Dropwizard admin port |
| `8009` | JMX port |
