---
service: "ingestion-jtier"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars, helm-values]
---

# Configuration

## Overview

ingestion-jtier uses the standard Dropwizard YAML configuration pattern, with environment-specific values injected at deployment time via Kubernetes environment variables and Helm values. Secrets (database credentials, API keys, Message Bus credentials) are injected as environment variables from Kubernetes secrets. The base configuration file is loaded by the Dropwizard application bootstrap; environment-specific overrides are applied via the jtier configuration conventions.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection URL for `continuumIngestionJtierPostgres` | yes | none | k8s-secret |
| `DATABASE_USER` | PostgreSQL username | yes | none | k8s-secret |
| `DATABASE_PASSWORD` | PostgreSQL password | yes | none | k8s-secret |
| `REDIS_HOST` | Redis hostname for `continuumIngestionJtierRedis` | yes | none | helm |
| `REDIS_PORT` | Redis port | yes | `6379` | helm |
| `REDIS_PASSWORD` | Redis authentication password | yes | none | k8s-secret |
| `MBUS_URL` | Message Bus broker URL | yes | none | k8s-secret |
| `MBUS_USERNAME` | Message Bus username | yes | none | k8s-secret |
| `MBUS_PASSWORD` | Message Bus password | yes | none | k8s-secret |
| `DEAL_MANAGEMENT_API_URL` | Base URL for Deal Management API | yes | none | helm |
| `TPIS_URL` | Base URL for Third-Party Inventory Service | yes | none | helm |
| `PARTNER_SERVICE_URL` | Base URL for Partner Service | yes | none | helm |
| `TAXONOMY_SERVICE_URL` | Base URL for Taxonomy Service | yes | none | helm |
| `VIATOR_API_URL` | Base URL for Viator partner API | yes | none | helm |
| `VIATOR_API_KEY` | Viator API authentication key | yes | none | k8s-secret |
| `MINDBODY_API_URL` | Base URL for Mindbody partner API | yes | none | helm |
| `MINDBODY_API_KEY` | Mindbody API authentication key | yes | none | k8s-secret |
| `BOOKER_API_URL` | Base URL for Booker partner API | yes | none | helm |
| `BOOKER_API_KEY` | Booker API authentication key | yes | none | k8s-secret |
| `REWARDS_NETWORK_API_URL` | Base URL for RewardsNetwork partner API | yes | none | helm |
| `REWARDS_NETWORK_API_KEY` | RewardsNetwork API authentication key | yes | none | k8s-secret |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found of a dedicated feature flag system in the service inventory. Feature enablement is controlled via Quartz job configuration (enabled/disabled) and partner-level pause state in PostgreSQL.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | yaml | Main Dropwizard application configuration — server, database pool, Redis, scheduler, and HTTP client settings |
| `config-staging.yml` | yaml | Staging environment overrides (if present, following jtier conventions) |
| `config-production.yml` | yaml | Production environment overrides (if present, following jtier conventions) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `ingestion-jtier-db-credentials` | PostgreSQL username and password for `continuumIngestionJtierPostgres` | k8s-secret |
| `ingestion-jtier-redis-credentials` | Redis authentication password for `continuumIngestionJtierRedis` | k8s-secret |
| `ingestion-jtier-mbus-credentials` | Message Bus broker credentials | k8s-secret |
| `ingestion-jtier-viator-api-key` | Viator external partner API key | k8s-secret |
| `ingestion-jtier-mindbody-api-key` | Mindbody external partner API key | k8s-secret |
| `ingestion-jtier-booker-api-key` | Booker external partner API key | k8s-secret |
| `ingestion-jtier-rewards-network-api-key` | RewardsNetwork external partner API key | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development / local**: Uses local Docker Compose for PostgreSQL and Redis; external partner API calls are typically mocked or pointed to sandbox endpoints
- **Staging (snc1)**: Connected to staging instances of all internal services; may use sandbox credentials for external partner APIs; Quartz job schedules may run at reduced frequency
- **Production (snc1 + sac1)**: Full partner API credentials; production database and Redis; Quartz jobs run on production schedule; deployed across two data centers for availability
