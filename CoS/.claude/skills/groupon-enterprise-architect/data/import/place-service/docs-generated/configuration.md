---
service: "place-service"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-central, helm-values]
---

# Configuration

## Overview

The M3 Place Service is configured through a combination of environment variables injected by Kubernetes Helm chart values (defined in `.meta/deployment/cloud/components/app/`), Groupon's internal config-central system (config files bundled at `/var/groupon/config-central/` inside the Docker image), and a secrets repository (`place-service-secrets`) that holds DB connection parameters and API keys. Per-environment overrides are layered in environment-specific Helm YAML files.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENV` | Current deployment environment identifier (e.g., `production-us-central1`) | yes | — | helm |
| `ACTIVE_ENV` | Active environment name used for config resolution | yes | — | helm |
| `MERCHANTDATA_ENV` | Merchant data environment name used by config-central | yes | — | helm |
| `LOG_LEVEL` | Application log level | no | `INFO` | helm |
| `OS_HOST` | Alias variable name for OpenSearch endpoint (resolved to endpoint variable value) | yes | — | helm |
| `M3_PLACEREAD_OS_PROD_ESDOMAIN_ENDPOINT` | OpenSearch cluster hostname for production environments | yes (prod) | — | helm |
| `M3_PLACEREAD_OS_STAGING_ESDOMAIN_ENDPOINT` | OpenSearch cluster hostname for staging environments | yes (staging) | — | helm |
| `M3_MEMORY_OPTS` | JVM heap size argument (e.g., `-Xmx12G` for prod US, `-Xmx2G` for staging) | no | — | helm |
| `MALLOC_ARENA_MAX` | Tuned to prevent virtual memory explosion in containers | no | `4` | helm |
| `INITIAL_RAM_PERCENTAGE` | Initial JVM heap as a percentage of container memory | no | `70.0` | helm |
| `MAX_RAM_PERCENTAGE` | Maximum JVM heap as a percentage of container memory | no | `80.0` | helm |
| `MAX_GC_PAUSE_MILLIS` | Target maximum GC pause time in milliseconds | no | `200` | helm |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Whether to verify APM server SSL certificate | no | `"false"` (staging) | helm |
| `SOURCE_NAMES` | JSON map of source ID to display name (used by sf-m3-synchronizer-worker) | yes (worker) | (see common.yml) | helm |
| `google_places_api_key` | Google Maps Places API key | yes | — | config-central (vault) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found in codebase for application-level feature flags beyond environment-based config.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Base Helm values for main app deployment (image, scaling, ports, probes, log config, common env vars) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production US (GCP us-central1) overrides: scaling (8–40 replicas), CPU (2500m–7500m), memory (14Gi–16Gi), env vars |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Production EU (AWS eu-west-1) overrides: scaling (3–25 replicas), CPU (2500m–4000m), memory (5Gi–10Gi), env vars |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging US overrides: scaling (3–5 replicas), CPU (1000m–2000m), memory (3200Mi–3600Mi) |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | Staging EU overrides |
| `.meta/deployment/cloud/components/m3-reverser-negotiator-worker/common.yml` | YAML | Helm values for reverse negotiator worker (scaling 3–15 replicas, 500m CPU, 950Mi–1Gi memory) |
| `.meta/deployment/cloud/components/sf-m3-synchronizer-worker/common.yml` | YAML | Helm values for Salesforce synchronizer worker (scaling 3–15 replicas, 300m CPU, 500Mi memory) |
| `docker/Dockerfile` | Dockerfile | Builds Tomcat 8.5/JRE 11 image with WAR artifact and config-central bundles |
| `/var/groupon/config-central/grouper/current/` | resources | Grouper taxonomy models bundled in Docker image |
| `/var/groupon/config-central/taxonomy/current/` | resources | Taxonomy config bundled in Docker image |
| `/var/groupon/config-central/sources/current/` | resources | Data source config bundled in Docker image |
| `doc/swagger.json` | JSON | OpenAPI 2.0 specification (Swagger) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `google_places_api_key` | Google Maps Places API key for geo-candidate lookup | config-central (vault-backed) |
| DB connection parameters | Postgres host, port, username, password for place database | `place-service-secrets` repo (k8s-secret) |
| Redis connection parameters | Redis cluster connection details for place cache | `place-service-secrets` repo (k8s-secret) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Environment | Cloud | Region | Replicas | CPU (req/limit) | Memory (req/limit) | JVM heap |
|-------------|-------|--------|----------|-----------------|---------------------|----------|
| staging-us-central1 | GCP | us-central1 | 3–5 | 1000m / 2000m | 3200Mi / 3600Mi | -Xmx2G |
| staging-europe-west1 | GCP | europe-west1 | 3–5 | (from staging-europe-west1.yml) | (from staging-europe-west1.yml) | — |
| production-us-central1 | GCP | us-central1 | 8–40 | 2500m / 7500m | 14Gi / 16Gi | -Xmx12G |
| production-eu-west-1 | AWS | eu-west-1 | 3–25 | 2500m / 4000m | 5Gi / 10Gi | — |

HPA target CPU utilization: 30% (production), 100% (staging-us-central1).
