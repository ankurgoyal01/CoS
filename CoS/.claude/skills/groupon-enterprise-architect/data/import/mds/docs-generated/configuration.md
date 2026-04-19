---
service: "mds"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, service-discovery]
---

# Configuration

## Overview

MDS is configured through environment variables, application configuration files (Spring Boot application.yml for the JTier layer, Node.js config files for the worker layer), and the Continuum service discovery mechanism for resolving internal service endpoints. Secrets are managed via the platform secret store and injected as environment variables at deployment time.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection string for the primary deal database | yes | none | env / vault |
| `REDIS_URL` | Redis connection string for queues, locks, and notifications | yes | none | env / vault |
| `MONGO_URL` | MongoDB connection string for legacy metadata store | yes | none | env / vault |
| `MESSAGE_BUS_URL` | Message bus (JMS/STOMP) broker connection | yes | none | env / vault |
| `SALESFORCE_API_URL` | Salesforce REST API base URL | yes | none | env |
| `SALESFORCE_AUTH_TOKEN` | Salesforce OAuth token or API key | yes | none | vault |
| `MARKETING_PLATFORM_URL` | Marketing Platform service endpoint | yes | none | service-discovery |
| `DEAL_CATALOG_SERVICE_URL` | Deal Catalog Service endpoint | yes | none | service-discovery |
| `DEAL_MANAGEMENT_API_URL` | Deal Management API endpoint | yes | none | service-discovery |
| `M3_PLACES_SERVICE_URL` | M3 Places Service endpoint | yes | none | service-discovery |
| `M3_MERCHANT_SERVICE_URL` | M3 Merchant Service endpoint | yes | none | service-discovery |
| `BHUVAN_SERVICE_URL` | Bhuvan Geo Service endpoint | yes | none | service-discovery |
| `PRICING_SERVICE_URL` | Pricing Service endpoint | yes | none | service-discovery |
| `LAZLO_API_URL` | Lazlo API Service endpoint | yes | none | service-discovery |
| `INVENTORY_SERVICE_URL` | Federated Inventory Service endpoint | yes | none | service-discovery |
| `SMA_METRICS_URL` | SMA Metrics endpoint | yes | none | service-discovery |
| `WORKER_CONCURRENCY` | Number of concurrent deal processing workers | no | platform default | env |
| `ENRICHMENT_RETRY_MAX` | Maximum retry attempts for failed enrichment | no | 3 | env |
| `ENRICHMENT_RETRY_BACKOFF_MS` | Base backoff interval for retry scheduling (ms) | no | 5000 | env |
| `LOCK_TTL_SECONDS` | Distributed lock TTL for per-deal processing | no | 300 | env |
| `FEED_GENERATION_SCHEDULE` | Cron expression for scheduled feed generation | no | platform default | env |
| `LOG_LEVEL` | Application log level | no | INFO | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `ENABLE_MONGO_READS` | Controls whether legacy MongoDB reads are active in JTier query paths | true | global |
| `ENABLE_INVENTORY_ENRICHMENT` | Enables real-time inventory status aggregation in deal responses | true | global |
| `ENABLE_CRM_ENRICHMENT` | Enables Salesforce CRM attribute enrichment in the pipeline | true | global |
| `ENABLE_PERFORMANCE_CACHING` | Enables caching of SMA performance metrics in PostgreSQL | true | global |

> Feature flags are inferred from the architecture model's component structure. Confirm exact flag names and configuration mechanism with the marketing-deals team.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `application.yml` | yaml | Spring Boot / JTier API configuration (server, datasource, service endpoints) |
| `config/default.json` | json | Node.js worker default configuration (queue settings, retry policies) |
| `config/production.json` | json | Node.js worker production overrides |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_URL` | PostgreSQL credentials | vault / k8s-secret |
| `REDIS_URL` | Redis authentication | vault / k8s-secret |
| `MONGO_URL` | MongoDB credentials (legacy) | vault / k8s-secret |
| `MESSAGE_BUS_URL` | Message bus broker credentials | vault / k8s-secret |
| `SALESFORCE_AUTH_TOKEN` | Salesforce API authentication | vault / k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Uses local/containerized PostgreSQL, Redis, and MongoDB instances. Message bus connects to a dev broker. Service discovery points to dev service instances. `WORKER_CONCURRENCY` set to 1 for debugging.
- **Staging**: Uses shared staging database and Redis instances. Full integration with staging versions of all upstream services. `LOG_LEVEL` set to DEBUG for enhanced observability.
- **Production**: Uses production-grade managed PostgreSQL, Redis, and MongoDB clusters. Full integration with production services. `WORKER_CONCURRENCY` tuned for production load. `ENRICHMENT_RETRY_MAX` and `LOCK_TTL_SECONDS` configured for production SLAs.
