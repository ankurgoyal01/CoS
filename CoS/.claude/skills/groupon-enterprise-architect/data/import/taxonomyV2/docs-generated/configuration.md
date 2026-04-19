---
service: "taxonomyV2"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secrets]
---

# Configuration

## Overview

Taxonomy V2 is configured through a combination of environment variables and JTier YAML configuration files mounted at runtime inside the container. The active configuration file is selected via the `JTIER_RUN_CONFIG` environment variable, which points to an environment- and region-specific YAML file (e.g., `production-us-west-1.yml`). Secrets such as database credentials, Redis connection strings, and Slack webhook URLs are managed as Kubernetes secrets and injected into the container at runtime (secret path: `.meta/deployment/cloud/secrets`). Non-secret tuning values (memory, CPU percentages) are set as plain environment variables.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the JTier YAML config file to load at startup | Yes | None | Kubernetes env (per-environment deployment YAML) |
| `ACTIVE_COLO` | Identifies the active deployment region (e.g., `us-west-1`, `us-central1`, `eu-west-1`) | Yes | None | Kubernetes env (per-environment deployment YAML) |
| `MALLOC_ARENA_MAX` | Limits glibc malloc arenas to prevent virtual memory explosion under high CPU counts | Yes | `4` | Kubernetes env (`common.yml`) |
| `MIN_RAM_PERCENTAGE` | Minimum JVM heap as a percentage of container memory | Yes | `70.0` | Kubernetes env (`common.yml`) |
| `MAX_RAM_PERCENTAGE` | Maximum JVM heap as a percentage of container memory | Yes | `70.0` | Kubernetes env (`common.yml`) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase. Taxonomy V2 does not use a runtime feature flag system. Behavior differences between environments are controlled via the JTier config file loaded at startup.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared Kubernetes deployment spec — image, scaling defaults, resource requests, log config, port config, APM enable |
| `.meta/deployment/cloud/components/app/production-us-west-1.yml` | YAML | Production AWS us-west-1 overrides — region, VPC, replicas, resource limits |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production AWS eu-west-1 overrides — region, VPC, replicas, resource limits |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production GCP us-central1 overrides |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | Production GCP europe-west1 overrides |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging GCP us-central1 overrides — region, VPC, VIP, replicas |
| `.meta/deployment/cloud/components/app/staging-us-west-1.yml` | YAML | Staging AWS us-west-1 overrides |
| `.meta/deployment/cloud/components/app/staging-us-west-2.yml` | YAML | Staging AWS us-west-2 overrides |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging GCP europe-west1 overrides |
| `.meta/.raptor.yml` | YAML | Raptor deployment type declaration (`archetype: jtier`, `type: api`, secret path) |
| `doc/swagger/config.yml` | YAML | Swagger UI configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Database credentials (username/password) | Postgres DaaS authentication for `taxonomyv2_prod` / `taxonomyv2_stg` databases | Kubernetes secret (`.meta/deployment/cloud/secrets`) |
| Redis connection credentials | RaaS Redis authentication for production and staging clusters | Kubernetes secret |
| Slack webhook URL | Slack incoming webhook for #taxonomy channel notifications | Kubernetes secret |
| SMTP credentials | Email gateway authentication for deployment alert emails | Kubernetes secret |
| JMS message bus credentials | Authentication for `jms.topic.taxonomyV2.cache.invalidate` and `jms.topic.taxonomyV2.content.update` | Kubernetes secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Environment | Region | Cloud | Key Differences |
|-------------|--------|-------|-----------------|
| Staging | us-west-1 (AWS) | AWS | `minReplicas: 1–3`, `ACTIVE_COLO: us-west-1`, uses staging DB and Redis endpoints |
| Staging | us-west-2 (AWS) | AWS | `minReplicas: 1–3`, `ACTIVE_COLO: us-west-2` |
| Staging | us-central1 (GCP) | GCP | `ACTIVE_COLO: us-central1`, VIP: `taxonomyv2.us-central1.conveyor.stable.gcp.groupondev.com` |
| Staging | europe-west1 (GCP) | GCP | `ACTIVE_COLO: europe-west1` |
| Production | us-west-1 (AWS) | AWS | `minReplicas: 3`, `maxReplicas: 20`, `enableVPA: true`, 10Gi–18Gi memory, `ACTIVE_COLO: us-west-1` |
| Production | eu-west-1 (AWS) | AWS | `minReplicas: 3`, `maxReplicas: 20`, `enableVPA: false`, 10Gi–15Gi memory, `ACTIVE_COLO: eu-west-1` |
| Production | us-central1 (GCP) | GCP | `ACTIVE_COLO: us-central1`, connects to GCP Postgres and Redis |
| Production | europe-west1 (GCP) | GCP | `ACTIVE_COLO: europe-west1` |

All environments use:
- HTTP port `8080`, admin port `8081`, JMX port `8009`
- CPU: 1000m request / 2000m limit
- APM enabled (`apm.enabled: true`)
- Log source type: `taxonomyv2`
