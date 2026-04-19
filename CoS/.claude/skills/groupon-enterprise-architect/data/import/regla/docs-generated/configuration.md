---
service: "regla"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, consul]
---

# Configuration

## Overview

regla is configured via Play Framework application configuration files (`application.conf` and environment-specific overrides), supplemented by environment variables. The PostgreSQL JDBC connection, Redis connection pool, Kafka SSL settings, Taxonomy Service endpoint, and rule cache sync intervals are all expressed in `application.conf`. Secrets (database credentials, Kafka keystores) are injected via environment variables at runtime. A taxonomy data cache and a rule cache are populated at service startup and refreshed on configurable sync intervals.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `POSTGRES_URL` | JDBC URL for `reglaPostgresDb` PostgreSQL database | yes | none | env |
| `POSTGRES_USER` | PostgreSQL database username | yes | none | env |
| `POSTGRES_PASSWORD` | PostgreSQL database password | yes | none | vault |
| `REDIS_HOST` | Hostname of the `reglaRedisCache` Redis instance | yes | none | env |
| `REDIS_PORT` | Port of the Redis instance | no | `6379` | env |
| `REDIS_TTL_SECONDS` | TTL for Redis cache entries | no | `403200` | env |
| `KAFKA_BOOTSTRAP_SERVERS` | Comma-separated Kafka broker addresses for stream job | yes | none | env |
| `KAFKA_SSL_TRUSTSTORE_LOCATION` | Path to Kafka SSL truststore file | yes | none | env |
| `KAFKA_SSL_TRUSTSTORE_PASSWORD` | Password for Kafka SSL truststore | yes | none | vault |
| `KAFKA_SSL_KEYSTORE_LOCATION` | Path to Kafka SSL keystore file | yes | none | env |
| `KAFKA_SSL_KEYSTORE_PASSWORD` | Password for Kafka SSL keystore | yes | none | vault |
| `KAFKA_SSL_KEY_PASSWORD` | Kafka SSL client key password | yes | none | vault |
| `TAXONOMY_SERVICE_URL` | Base URL for Taxonomy Service v2 HTTP calls | yes | none | env |
| `TAXONOMY_CACHE_SYNC_INTERVAL_SECONDS` | Interval at which the taxonomy tree cache is refreshed from Taxonomy Service v2 | no | `3600` | env |
| `RULE_CACHE_SYNC_INTERVAL_SECONDS` | Interval at which the stream job reloads active rules from PostgreSQL | no | `300` | env |
| `APPLICATION_PORT` | HTTP port for the Play Framework application | no | `9000` | env |
| `APPLICATION_SECRET` | Play Framework application secret for session signing | yes | none | vault |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase for a dedicated feature flag system in regla.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `conf/application.conf` | HOCON (Play) | Primary application configuration: database pool, Redis connection, Kafka consumer/producer settings, taxonomy and rule cache intervals, HTTP client timeouts |
| `conf/routes` | Play routes DSL | URL routing for all API endpoints (`/rule`, `/ruleInstance/registerRuleEvents`, `/userHasDealPurchaseSince`, `/userHasAnyPurchaseEver`, `/categoryInCategoryTree`, `/health`, `/status`) |
| `conf/logback.xml` | XML | Logback logging configuration; controls log levels and appenders for reglaService and reglaStreamJob |
| `build.sbt` | SBT DSL | Library dependency manifest and build settings |
| `project/plugins.sbt` | SBT DSL | SBT plugin declarations including Play plugin |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `POSTGRES_PASSWORD` | PostgreSQL database password for `reglaPostgresDb` | vault |
| `KAFKA_SSL_TRUSTSTORE_PASSWORD` | Password for Kafka SSL truststore used by stream job | vault |
| `KAFKA_SSL_KEYSTORE_PASSWORD` | Password for Kafka SSL keystore used by stream job | vault |
| `KAFKA_SSL_KEY_PASSWORD` | Kafka SSL client key password | vault |
| `APPLICATION_SECRET` | Play Framework session signing secret | vault |

> Secret values are NEVER documented. Only names and rotation policies are listed here.

## Per-Environment Overrides

- **Development**: `application.conf` references a local PostgreSQL instance (typically Docker Compose); Redis runs locally; Kafka may be mocked or pointed at a development cluster without SSL; `REDIS_TTL_SECONDS` defaults to `403200` (4.67 days); taxonomy cache uses a reduced sync interval for faster iteration
- **Staging (NA us-west-1)**: Full Kafka SSL configuration active; PostgreSQL and Redis are managed instances in the NA staging environment; `TAXONOMY_SERVICE_URL` points to staging Taxonomy Service v2; Kubernetes ConfigMaps provide non-secret values; secrets injected from Vault
- **Production NA (us-west-1)**: Production PostgreSQL and Redis with full connection pooling; Kafka SSL with production certificates; `REDIS_TTL_SECONDS=403200`; `RULE_CACHE_SYNC_INTERVAL_SECONDS=300`; all secrets from Vault
- **Production EMEA (eu-west-1)**: Mirrors NA production configuration with EMEA-regional endpoints for PostgreSQL, Redis, Kafka brokers, and Taxonomy Service v2
