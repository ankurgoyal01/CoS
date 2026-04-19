---
service: "deal-performance-api-v2"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files", "k8s-secrets"]
---

# Configuration

## Overview

The service is configured via YAML config files selected at runtime by the `JTIER_RUN_CONFIG` environment variable. Per-environment config files are located at `src/main/resources/config/`. Database credentials are injected as environment variables sourced from Kubernetes secrets (via the Raptor/Conveyor Cloud secrets path `.meta/deployment/cloud/secrets`). Non-secret environment variables are declared in `.meta/deployment/cloud/components/app/common.yml`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the YAML config file to load at startup | Yes (in cloud) | None (dev uses default) | Kubernetes `envVars` in deployment config |
| `DAAS_APP_USERNAME` | PostgreSQL application username for both primary and session connections | Yes | None | Kubernetes secret (via `.meta/deployment/cloud/secrets`) |
| `DAAS_APP_PASSWORD` | PostgreSQL application password for both primary and session connections | Yes | None | Kubernetes secret (via `.meta/deployment/cloud/secrets`) |
| `MALLOC_ARENA_MAX` | JVM native memory arena limit — reduces virtual memory explosion under concurrent load | No | `4` (set in `common.yml`) | Kubernetes `envVars` |

> Secret values are NEVER documented. Only names and rotation policies.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `shouldUsePrimaryDb` | Per-request query parameter — routes DB query to the primary (RW) connection instead of the replica | `false` | per-request |
| `shouldUseNewSQL` | Per-request query parameter — selects the optimized single-metric SQL template (only applies when a single metric is requested) | `false` | per-request |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development configuration; connects to `localhost:5432` |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | Staging environment; points to staging GDS PostgreSQL host |
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | Production environment; points to production GDS read-only replica |
| `src/main/resources/swagger.yaml` | YAML | OpenAPI 2.0 specification loaded at runtime by the Swagger endpoint |
| `src/main/resources/metrics.yml` | YAML | Metrics reporting destination (`http://localhost:8186/`), flush frequency (10s) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared Kubernetes deployment settings (scaling, ports, resources) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production-specific scaling and resource overrides |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging-specific scaling overrides |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DAAS_APP_USERNAME` | PostgreSQL username for application DB connections | Kubernetes secret (Raptor secrets path) |
| `DAAS_APP_PASSWORD` | PostgreSQL password for application DB connections | Kubernetes secret (Raptor secrets path) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Development | Staging | Production |
|---------|-------------|---------|------------|
| `server.maxThreads` | 50 | 50 | 100 |
| `server.minThreads` | 8 | 8 | 50 |
| `logging.level` | DEBUG | INFO | INFO |
| `postgres.host` | `localhost` | `deal-performance-service-v2-rw-na-staging-db.gds.stable.gcp.groupondev.com` | `deal-performance-service-v2-ro-na-production-db.gds.prod.gcp.groupondev.com` |
| `postgres.database` | `postgres` | `deal_perf_v2_stg` | `deal_perf_v2_prod` |
| `steno.stenoHttpStartLoggingEnabled` | (not set) | `false` | `false` |
| Kubernetes min/max replicas | N/A | 2 / 3 | 3 / 10 |
| CPU request (main container) | N/A | 500m | 3000m |
| Memory request / limit (main container) | N/A | 1900Mi / 2000Mi | 4500Mi / 5500Mi |
