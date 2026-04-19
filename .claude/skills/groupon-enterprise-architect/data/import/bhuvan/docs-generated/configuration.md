---
service: "bhuvan"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files", "k8s-secret"]
---

# Configuration

## Overview

Bhuvan is configured via a combination of YAML configuration files (JTier / Dropwizard convention), environment variables injected by the Kubernetes deployment, and secrets provisioned as Kubernetes secrets. The active config file is selected via the `JTIER_RUN_CONFIG` environment variable pointing to the environment-specific YAML at runtime. Development configuration lives in `src/main/resources/config/development.yml`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active JTier YAML config file for the running environment | yes | (none) | env (k8s configmap per environment) |
| `USE_TELEGRAF_METRICS` | Enables Telegraf metrics reporting | no | `"true"` | env (common.yml) |
| `MIN_RAM_PERCENTAGE` | Minimum JVM RAM threshold percentage for heap tuning | no | `"90.0"` | env (common.yml) |
| `MAX_RAM_PERCENTAGE` | Maximum JVM RAM threshold percentage for heap tuning | no | `"90.0"` | env (common.yml) |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent virtual memory explosion and OOM kills in containerized JVM | no | `4` | env (common.yml) |
| `GEO_MAXMIND_PACKAGE` | MaxMind GeoIP2 database package name baked into the Docker image | yes | `GeoIP2-City_20250211` | Dockerfile ENV |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| Optimize/Finch experiment flags | Control A/B experiment variants for autocomplete and geo behavior | Default behavior (no override) | Per-request (experiment bucketing via Expy) |

> Specific experiment flag names are managed in the Optimize/Finch platform, not in this repository.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | yaml | JTier Dropwizard config for local development |
| `.meta/deployment/cloud/components/app/common.yml` | yaml | Common Kubernetes deployment config (scaling, ports, probes, sidecars) |
| `.meta/deployment/cloud/components/app/common_aws.yml` | yaml | AWS-specific common Kubernetes deployment overrides |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | yaml | Staging GCP us-central1 environment config (VIP, scaling, resource limits) |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | yaml | Staging GCP europe-west1 environment config |
| `.meta/deployment/cloud/components/app/staging-us-west-1.yml` | yaml | Staging AWS us-west-1 environment config |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | yaml | Production GCP us-central1 environment config |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | yaml | Production GCP europe-west1 environment config |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | yaml | Production AWS eu-west-1 environment config |
| `.meta/raptor.yml` | yaml | Raptor deployment metadata |
| `.deploy_bot.yml` | yaml | DeployBot automation config with environment targets and Kubernetes clusters |
| `doc/swagger/config.yml` | yaml | Swagger UI configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Postgres credentials (DaaS) | Database username, password, and connection details for Bhuvan Postgres | k8s-secret (DaaS provisioned) |
| Redis credentials (RaaS) | Redis connection credentials for Memorystore cluster | k8s-secret (RaaS provisioned) |
| External API keys (Google Maps, MapTiler, Avalara, Bhoomi) | Authentication tokens for external geocoding and maps APIs | k8s-secret |
| Kafka SSL keystore credentials (Logstash sidecar) | SSL keystore/truststore passwords for Logstash Kafka output | k8s-secret (configmap references password literals) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Environment | Region | CPU Request | Memory Request/Limit | Min/Max Replicas | Config Key |
|-------------|--------|-------------|----------------------|-----------------|------------|
| staging | GCP us-central1 | 1500m | 4.5Gi / 5Gi | 3 / 17 | `staging-us-central1.yml` |
| staging | GCP europe-west1 | (inherits common) | (inherits common) | 3 / 17 | `staging-europe-west1.yml` |
| staging | AWS us-west-1 | (inherits common) | (inherits common) | (inherits common) | `staging-us-west-1.yml` |
| production | GCP us-central1 | 1000m | 12Gi / 15Gi | 3 / 10 | `production-us-central1.yml` |
| production | GCP europe-west1 | (inherits common) | (inherits common) | (inherits common) | `production-europe-west1.yml` |
| production | AWS eu-west-1 | (inherits common) | (inherits common) | (inherits common) | `production-eu-west-1.yml` |

Common defaults (all environments): HTTP port 8080, admin port 8081, health check at `/grpn/healthcheck` on port 8080, Logstash sidecar for log forwarding, APM enabled.
