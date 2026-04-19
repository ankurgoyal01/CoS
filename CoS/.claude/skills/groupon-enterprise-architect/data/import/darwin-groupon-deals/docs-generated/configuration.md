---
service: "darwin-groupon-deals"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

The Darwin Aggregator Service follows the Dropwizard configuration pattern: a YAML configuration file (typically `config.yml`) is the primary config source at startup, with environment-specific values injected via environment variables. Deployment-time values (replica counts, resource limits, service endpoints) are managed through Helm chart values. Secrets (credentials for Redis, Elasticsearch, Watson, Kafka, and downstream services) are injected as environment variables from a secrets store at deploy time.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ELASTICSEARCH_URL` | Elasticsearch cluster endpoint for deal index queries | yes | None | helm / env |
| `REDIS_HOST` | Redis cluster hostname for response caching | yes | None | helm / env |
| `REDIS_PORT` | Redis cluster port | yes | `6379` | helm / env |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka broker list for async messaging | yes | None | helm / env |
| `WATSON_OBJECT_STORAGE_URL` | Watson Object Storage endpoint for ML model artifact access | yes | None | helm / env |
| `WATSON_OBJECT_STORAGE_BUCKET` | Watson Object Storage bucket name for ML model artifacts | yes | None | helm / env |
| `DEAL_CATALOG_SERVICE_URL` | Base URL for Deal Catalog Service | yes | None | helm / env |
| `BADGES_SERVICE_URL` | Base URL for Badges Service | yes | None | helm / env |
| `USER_IDENTITIES_SERVICE_URL` | Base URL for User Identities Service | yes | None | helm / env |
| `GEO_PLACES_SERVICE_URL` | Base URL for Geo Places Service | yes | None | helm / env |
| `GEO_DETAILS_SERVICE_URL` | Base URL for Geo Details Service | yes | None | helm / env |
| `CARDATRON_SERVICE_URL` | Base URL for Cardatron Service | yes | None | helm / env |
| `ALLIGATOR_DECK_CONFIG_URL` | Base URL for Alligator Deck Config Service | yes | None | helm / env |
| `AUDIENCE_USER_ATTRIBUTES_URL` | Base URL for Audience User Attributes Service | yes | None | helm / env |
| `CITRUS_ADS_URL` | Base URL for Citrus Ads Service | no | None | helm / env |
| `TARGETED_DEAL_MESSAGE_URL` | Base URL for Targeted Deal Message Service | no | None | helm / env |
| `RECENTLY_VIEWED_DEALS_URL` | Base URL for Recently Viewed Deals Service | no | None | helm / env |
| `SPELL_CORRECTION_URL` | Base URL for Spell Correction Service | no | None | helm / env |
| `SERVER_PORT` | HTTP port for the Dropwizard application | yes | `8080` | helm / env |
| `ADMIN_PORT` | Admin port for Dropwizard admin endpoints (`/admin/hystrix`) | yes | `8081` | helm / env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are recorded here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `booster_ab_experiments` | Controls active A/B experiment configurations for deal boost ranking | Managed via `PUT /booster_ab_experiments` | per-region |

> Additional feature flags may exist. Confirm with service owner (relevance-engineering@groupon.com).

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` | yaml | Main Dropwizard application configuration (server, logging, database/cache/messaging endpoints) |
| `config-staging.yml` | yaml | Staging environment overrides (if present) |
| `helm/values.yaml` | yaml | Helm chart values for Kubernetes deployment (resource limits, replica counts, image tags) |
| `helm/values-production.yaml` | yaml | Production Helm overrides |

> Exact file paths within the repository should be confirmed with the service owner.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `ELASTICSEARCH_USERNAME` | Elasticsearch cluster authentication username | k8s-secret / vault |
| `ELASTICSEARCH_PASSWORD` | Elasticsearch cluster authentication password | k8s-secret / vault |
| `REDIS_PASSWORD` | Redis cluster authentication credential | k8s-secret / vault |
| `KAFKA_SASL_USERNAME` | Kafka SASL authentication username | k8s-secret / vault |
| `KAFKA_SASL_PASSWORD` | Kafka SASL authentication password | k8s-secret / vault |
| `WATSON_API_KEY` | Watson Object Storage / IBM Cloud API key | k8s-secret / vault |
| `CITRUS_ADS_API_KEY` | Citrus Ads API authentication key | k8s-secret / vault |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development / local**: Uses local Dropwizard config file; external services may be mocked or pointed at dev instances
- **Staging**: Helm values override service URLs to point at staging-tier instances of Deal Catalog, Badges, Geo, and other dependencies; reduced replica count
- **Production**: Full replica count across multi-region deployments (SNC1, DUB1, SAC1); all secrets injected from production vault; Elasticsearch and Redis point at production clusters
