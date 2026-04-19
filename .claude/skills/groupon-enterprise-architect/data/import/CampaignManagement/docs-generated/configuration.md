---
service: "email_campaign_management"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

CampaignManagement is configured through environment variables and config files. Runtime configuration values (feature flags, send parameters) are also resolved via the GConfig service at request time. No Consul or Vault integration was directly identifiable from the architecture inventory; secret management follows Continuum platform conventions.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection string for `continuumCampaignManagementPostgres` | yes | none | env |
| `REDIS_URL` | Redis connection string for `continuumCampaignManagementRedis` | yes | none | env |
| `PORT` | HTTP port the Express server binds to | no | 3000 | env |
| `NODE_ENV` | Runtime environment selector (development, staging, production) | yes | none | env |
| `GEOPLACE_SERVICE_URL` | Base URL for `continuumGeoPlacesService` | yes | none | env |
| `ROCKETMAN_SERVICE_URL` | Base URL for the Rocketman messaging delivery service | yes | none | env |
| `RTAMS_SERVICE_URL` | Base URL for the RTAMS audience service | yes | none | env |
| `TOKEN_SERVICE_URL` | Base URL for the Token Service | yes | none | env |
| `GCONFIG_SERVICE_URL` | Base URL for the GConfig runtime configuration service | yes | none | env |
| `EXPY_API_KEY` | API key for Expy experimentation SDK (`@grpn/expy.js`) | yes | none | env |
| `GCS_BUCKET` | Google Cloud Storage bucket name for deal assignment files | yes | none | env |
| `GCS_CREDENTIALS` | Path or JSON blob for GCS service account credentials | yes | none | env |
| `HDFS_HOST` | HDFS WebHDFS host for deal file archival | no | none | env |
| `HDFS_PORT` | HDFS WebHDFS port | no | 50070 | env |
| `INFLUX_HOST` | InfluxDB host for metrics emission | no | none | env |
| `INFLUX_DATABASE` | InfluxDB database name for service metrics | no | none | env |
| `LOG_LEVEL` | Winston log level (error, warn, info, debug) | no | info | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found. Runtime feature flags are expected to be resolved via the GConfig service at request time rather than stored as static environment variables.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/default.json` | JSON | Default application configuration values (connection timeouts, pool sizes, service URLs) |
| `config/production.json` | JSON | Production-specific overrides for connection parameters and external service URLs |
| `config/development.json` | JSON | Development environment overrides |

> Note: Specific config file names are inferred from the Node.js `config` module convention. Confirm with the service owner.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_URL` | PostgreSQL connection credentials including password | env / platform secret store |
| `REDIS_URL` | Redis connection credentials | env / platform secret store |
| `EXPY_API_KEY` | Expy experimentation service API key | env / platform secret store |
| `GCS_CREDENTIALS` | Google Cloud Storage service account key | env / platform secret store |

> Secret values are NEVER documented. Only names and purposes are listed here.

## Per-Environment Overrides

- **Development**: Local PostgreSQL and Redis instances; external service URLs may point to development stubs or sandbox environments.
- **Staging**: Staging PostgreSQL and Redis clusters; Rocketman, RTAMS, and GConfig pointed at staging endpoints.
- **Production**: Production PostgreSQL (primary + read-only replicas) and Redis clusters; all external services at production endpoints; InfluxDB metrics enabled.
