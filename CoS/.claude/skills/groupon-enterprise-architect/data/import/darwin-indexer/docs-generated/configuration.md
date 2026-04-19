---
service: "darwin-indexer"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [config-files, env-vars]
---

# Configuration

## Overview

darwin-indexer follows the standard Dropwizard configuration model: a primary YAML configuration file provides all service settings at startup, with environment-specific values injected via environment variable substitution within the YAML. This covers Elasticsearch cluster coordinates, PostgreSQL connection details, upstream service base URLs, Kafka broker configuration, Redis connection, and Quartz scheduler cron expressions.

## Environment Variables

> Specific variable names are not discoverable from the architecture DSL model alone. The following variables are expected based on Dropwizard conventions and the service's known integrations.

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ELASTICSEARCH_HOST` | Elasticsearch cluster hostname or endpoint | yes | none | env |
| `ELASTICSEARCH_PORT` | Elasticsearch cluster port | yes | `9300` | env |
| `ELASTICSEARCH_CLUSTER_NAME` | Elasticsearch cluster name for transport client connection | yes | none | env |
| `DB_URL` | PostgreSQL JDBC connection URL for indexer metadata | yes | none | env |
| `DB_USER` | PostgreSQL username | yes | none | env |
| `DB_PASSWORD` | PostgreSQL password | yes | none | vault |
| `REDIS_HOST` | Redis host for feature/sponsored data cache reads | yes | none | env |
| `REDIS_PORT` | Redis port | yes | `6379` | env |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka broker list for publishing `ItemIntrinsicFeatureEvent` | yes | none | env |
| `DEAL_CATALOG_BASE_URL` | Base URL for the Deal Catalog Service REST API | yes | none | env |
| `TAXONOMY_SERVICE_BASE_URL` | Base URL for the Taxonomy Service REST API | yes | none | env |
| `GEO_SERVICE_BASE_URL` | Base URL for the Geo Service REST API | yes | none | env |
| `MERCHANT_API_BASE_URL` | Base URL for the Merchant API REST API | yes | none | env |
| `INVENTORY_SERVICE_BASE_URL` | Base URL for the Inventory Service REST API | yes | none | env |
| `BADGES_SERVICE_BASE_URL` | Base URL for the Badges Service REST API | yes | none | env |
| `WATSON_S3_BUCKET` | S3 bucket name for Watson item feature data | yes | none | env |
| `ADMIN_PORT` | Dropwizard admin server port | no | `9001` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found. No feature flag system (e.g., LaunchDarkly, Unleash) is referenced in the architecture inventory. Index behavior is controlled via Quartz schedule configuration and YAML settings.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` (or environment variant) | YAML | Primary Dropwizard configuration: server settings, database pool, Elasticsearch client, Kafka producer, Redis client, upstream service URLs, Quartz job schedules, logging |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_PASSWORD` | PostgreSQL authentication credential | vault / env |
| Kafka auth credentials | Kafka broker authentication (if mTLS or SASL configured) | vault |
| AWS credentials / IAM role | S3 access for Watson Feature Bucket | vault / IAM |

> Secret values are NEVER documented. Only names and rotation policies are noted here.

## Per-Environment Overrides

Dropwizard supports environment variable substitution within YAML using `${VAR_NAME}` syntax. Environment-specific configuration is managed by supplying different environment variable values at deployment time:

- **Development**: Local Elasticsearch, PostgreSQL, and Redis instances; Kafka may be mocked or pointed at a dev cluster; reduced Quartz schedule frequency
- **Staging**: Staging-tier Elasticsearch cluster and PostgreSQL; connected to staging versions of all upstream services; Quartz schedules may be reduced to avoid unnecessary load
- **Production**: Full Elasticsearch cluster; production PostgreSQL; all upstream services at production endpoints; full Quartz schedule for deal freshness SLAs
