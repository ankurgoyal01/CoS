---
service: "global_subscription_service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The Global Subscription Service is configured through a combination of environment variables and JTier YAML run configuration files. The active configuration file is selected via the `JTIER_RUN_CONFIG` environment variable, which points to an environment- and region-specific YAML file mounted into the container. Kafka TLS certificates are initialized at startup by executing `kafka-tls-v2.sh` before the JVM starts. Batch mode is controlled by the `BATCH` environment variable; when set to `true`, MBus and Kafka connections are skipped.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the active JTier YAML configuration file | yes | `/var/groupon/jtier/config/cloud/<env>-<region>.yml` | helm / deployment manifest |
| `KAFKA_ENDPOINT` | Kafka bootstrap server address (host:port) | yes | — | helm / deployment manifest (per-region) |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent container OOM kills | no | `4` | common deployment manifest |
| `BATCH` | When `true`, starts the service in batch mode (skips MBus and Kafka; email calculation only) | no | `false` (unset) | helm / deployment manifest |
| `ACTIVE_COLO` | Data center / colo identifier (legacy, used in older Dockerfile) | no | `snc1` | Dockerfile default |
| `ACTIVE_ENV` | Runtime environment name (legacy, used in older Dockerfile) | no | `development` | Dockerfile default |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `messageBusConsumersEnabled` | Enables or disables MBus consumer threads at startup | `true` (enabled) | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `/var/groupon/jtier/config/cloud/production-us-central1.yml` | YAML | JTier run config for GCP production US Central 1 |
| `/var/groupon/jtier/config/cloud/production-europe-west1.yml` | YAML | JTier run config for GCP production Europe West 1 |
| `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | YAML | JTier run config for GCP staging US Central 1 |
| `.meta/deployment/cloud/components/gss/common.yml` | YAML | Shared Kubernetes deployment config for gss component |
| `.meta/deployment/cloud/components/gss/production-us-central1.yml` | YAML | Production US Central 1 deployment overrides |
| `.meta/deployment/cloud/components/gss/production-europe-west1.yml` | YAML | Production Europe West 1 deployment overrides |
| `.meta/deployment/cloud/components/batch/common.yml` | YAML | Shared Kubernetes deployment config for batch component |
| `doc/swagger/swagger.yaml` | YAML | OpenAPI 2.0 API specification |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| PostgreSQL credentials (SMS Consent DB) | Database username/password for `continuumSmsConsentPostgres` | k8s-secret / JTier secrets |
| PostgreSQL credentials (Push Token DB) | Database username/password for `continuumPushTokenPostgres` (`ptsPostgres` config key) | k8s-secret / JTier secrets |
| Cassandra credentials | Cassandra cluster authentication for `continuumPushTokenCassandra` | k8s-secret / JTier secrets |
| Kafka TLS certificates | Client certificates for Kafka TLS authentication | k8s-secret (mounted at `/var/groupon/certs`) |
| User Service credentials | Auth credentials for `user_service` Retrofit client | k8s-secret / JTier secrets |
| Consent Service credentials | Auth credentials for `consent_service` Retrofit client | k8s-secret / JTier secrets |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The deployment manifests under `.meta/deployment/cloud/components/gss/` define environment- and region-specific overrides:

- **Production US Central 1**: 10–90 replicas; CPU 1200m–10000m; memory 4Gi–10Gi; HPA target utilization 15%; `JTIER_RUN_CONFIG` points to `production-us-central1.yml`
- **Production Europe West 1**: 4–64 replicas; CPU 2000m request; memory 4Gi–10Gi; `JTIER_RUN_CONFIG` points to `production-europe-west1.yml`
- **Staging US Central 1**: 1–2 replicas; VPA enabled; `JTIER_RUN_CONFIG` points to `staging-us-central1.yml`
- **Common (all envs)**: 3–15 replicas baseline; HTTP port 9000; admin port 9001; JMX port 8009; readiness and liveness probes at `/grpn/healthcheck` (port 9000, 30s delay, 30s period); JSON logging to `/var/groupon/jtier/logs/steno.log`
