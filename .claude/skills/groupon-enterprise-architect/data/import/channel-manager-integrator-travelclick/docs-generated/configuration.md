---
service: "channel-manager-integrator-travelclick"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, helm-values, k8s-secrets, jtier-run-config-yaml]
---

# Configuration

## Overview

The service is configured through a combination of environment variables, JTier run-config YAML files (one per environment, referenced by `JTIER_RUN_CONFIG`), and Kubernetes secrets injected at deploy time via Helm. Non-secret configuration is managed in the `.meta/deployment/cloud/components/app/` YAML files per environment. Secrets are stored in `.meta/deployment/cloud/secrets/` (not committed) and injected as Kubernetes secrets.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the JTier run-config YAML for the active environment | yes | `/var/groupon/jtier/config/cloud/<env>-<region>.yml` | Helm / env-specific YAML |
| `ACTIVE_ENV` | Active deployment environment (`staging`, `production`) | yes | `development` (Dockerfile default) | Helm / env-specific YAML |
| `ACTIVE_COLO` | Active colo/region identifier | yes | `snc1` (Dockerfile default) | Helm / env-specific YAML |
| `MALLOC_ARENA_MAX` | Limits glibc memory arenas to prevent OOM from vmem explosion | yes | `4` | `common.yml` |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Whether to verify the APM server TLS certificate | no | `"false"` (production-us-central1) | env-specific YAML |
| `JTIER_DIR` | Base directory for the JTier service runtime | yes | `/var/groupon/jtier` | Dockerfile |
| `LANG` | Locale setting for the container | yes | `en_US.UTF-8` | `.ci/Dockerfile` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase of feature flags beyond environment-driven configuration.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared Kubernetes deployment configuration: scaling (minReplicas 3, maxReplicas 15), resource requests, ports, log config, APM |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production US Central 1 overrides: GCP cluster, namespace, replica counts, APM endpoint, probe timeouts |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production EU West 1 overrides |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging US Central 1 overrides: replica counts (min 1, max 2), Telegraf URL, APM endpoint |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging Europe West 1 overrides |
| `.mvn/jvm.config` | Text | JVM flags: `-Xmx2048m -Xms512m`, metrics directory, headless mode |
| `doc/schema.yml` | YAML (OpenAPI 3.0) | API schema definition |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `.meta/deployment/cloud/secrets/cloud/<env>.yml` | TravelClick credentials, database credentials, MBus credentials, Kafka credentials | Kubernetes secrets (injected at deploy time via Helm) |
| Client TLS certificates | TLS client certificates for outbound connections | Kubernetes volume mount at `/var/groupon/certs` |

> Secret values are NEVER documented. Only names and rotation policies are referenced.

## Per-Environment Overrides

| Environment | Region | Notable Differences |
|-------------|--------|---------------------|
| Development | Local | `ACTIVE_ENV=development`, `ACTIVE_COLO=snc1`; uses local MySQL and Kafka via Docker Compose |
| Staging | us-central1 | Min 1 / max 2 replicas; staging MBus and Kafka endpoints; staging APM endpoint |
| Staging | europe-west1 | Same as staging US; separate GCP cluster |
| Production | us-central1 | Min 2 / max 15 replicas; 1000m CPU request; 60s probe timeouts; production APM endpoint |
| Production | eu-west-1 | Same resource profile as production US; separate GCP cluster |

Internal base URLs per colo (from `.service.yml`):
- SNC1 production: `http://getaways-channel-manager-integrator-tc-app-vip.snc1`
- SNC1 staging: `http://getaways-channel-manager-integrator-tc-app-vip-staging.snc1`
- SAC1 production: `http://getaways-channel-manager-integrator-tc-app-vip.sac1`
