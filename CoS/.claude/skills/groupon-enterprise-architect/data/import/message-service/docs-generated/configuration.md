---
service: "message-service"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

The CRM Message Service follows Play Framework 2.2.x configuration conventions. Runtime configuration is provided through Play's `application.conf` (HOCON format) with environment-specific overrides. Environment variables supply secrets and deployment-specific values (database URLs, Kafka broker addresses, MBus connection details, GCP credentials). The UI layer is configured at build time via Webpack environment variables.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_URL` | MySQL connection URL for `continuumMessagingMySql` | yes | — | env |
| `DB_USER` | MySQL username | yes | — | env |
| `DB_PASSWORD` | MySQL password | yes | — | env / vault |
| `REDIS_HOST` | Redis hostname for `continuumMessagingRedis` | yes | — | env |
| `REDIS_PORT` | Redis port | yes | 6379 | env |
| `KAFKA_BROKERS` | Kafka broker addresses for `ScheduledAudienceRefreshed` topic | yes | — | env |
| `KAFKA_TOPIC_SCHEDULED_AUDIENCE` | Kafka topic name for scheduled audience events | yes | — | env |
| `MBUS_ENDPOINT` | MBus connection endpoint for `CampaignMetaData` publication | yes | — | env |
| `BIGTABLE_PROJECT` | GCP project ID for `continuumMessagingBigtable` | yes (cloud) | — | env |
| `BIGTABLE_INSTANCE` | GCP Bigtable instance ID | yes (cloud) | — | env |
| `GCP_STORAGE_BUCKET` | GCP Storage bucket for audience export files | yes (cloud) | — | env |
| `CASSANDRA_HOSTS` | Cassandra seed hosts for `continuumMessagingCassandra` | yes (legacy) | — | env |
| `AMS_BASE_URL` | Base URL for Audience Management Service | yes | — | env |
| `TAXONOMY_BASE_URL` | Base URL for Taxonomy Service | yes | — | env |
| `GEO_SERVICE_BASE_URL` | Base URL for Geo Service | yes | — | env |
| `EMAIL_SERVICE_BASE_URL` | Base URL for Email Campaign Management | yes | — | env |
| `GIMS_BASE_URL` | Base URL for GIMS image management | yes | — | env |

> IMPORTANT: Secret values are never documented. Only variable names and purposes are listed. Actual values are managed in the team's secret store.

## Feature Flags

> No evidence found in the architecture inventory for specific feature flag names. Finch/Optimizely integration suggests experiment-driven flags are used for targeting configuration.

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| > No evidence found | — | — | — |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `conf/application.conf` | HOCON | Play Framework main configuration: database pool, routes, Akka settings, plugin config |
| `conf/routes` | Play routes | URL-to-controller mapping for all `/api` and `/campaign` endpoints |
| `conf/prod.conf` | HOCON | Production environment overrides (database URLs, pool sizes, timeouts) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_PASSWORD` | MySQL authentication | vault / env |
| `MBUS_CREDENTIALS` | MBus publisher authentication | vault / env |
| `GCP_SERVICE_ACCOUNT_KEY` | GCP Bigtable and Storage access | vault / env |
| `KAFKA_CREDENTIALS` | Kafka consumer authentication | vault / env |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Development**: Local MySQL/Redis instances; Kafka and Bigtable may be mocked or pointed at dev-tier clusters; `application.conf` dev overrides reduce pool sizes and timeouts
- **Staging**: Shared staging MySQL, Redis, Bigtable; Kafka broker pointing to staging topics; AMS and other service URLs point to staging endpoints
- **Production**: Full cluster MySQL with replication; production Redis cluster; Bigtable production instance with scaling managed via `/api/bigtable/scale`; Cassandra used in non-GCP production environments
