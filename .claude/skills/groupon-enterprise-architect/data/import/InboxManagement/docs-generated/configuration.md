---
service: "inbox_management_platform"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [config-files, db-runtime-config, env-vars]
---

# Configuration

## Overview

InboxManagement uses a layered configuration approach. Static application configuration is loaded at startup via HOCON files (typesafe-config 1.3.0). Runtime operational configuration (throttle rates, daemon active flags, circuit breakers) is stored in `continuumInboxManagementPostgres` and managed via the `/im/admin/config/*` REST API — allowing live changes without redeployment. Infrastructure configuration (database URLs, credentials) is supplied via environment variables or Kubernetes secrets.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `REDIS_HOST` | Hostname(s) for sharded Redis cluster | yes | none | env / helm |
| `REDIS_PORT` | Port for Redis connections | yes | `6379` | env / helm |
| `POSTGRES_URL` | JDBC connection URL for InboxManagement Postgres | yes | none | env / k8s-secret |
| `POSTGRES_USER` | Postgres username | yes | none | env / k8s-secret |
| `POSTGRES_PASSWORD` | Postgres password | yes | none | k8s-secret |
| `EDW_JDBC_URL` | Hive JDBC URL for EDW user attribute loading | yes | none | env / k8s-secret |
| `EDW_USER` | EDW/Hive username | yes | none | k8s-secret |
| `EDW_PASSWORD` | EDW/Hive password | yes | none | k8s-secret |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka broker addresses for consumer/producer | yes | none | env / helm |
| `KAFKA_GROUP_ID` | Consumer group ID for Kafka consumers | yes | none | env / helm |
| `APP_ENV` | Deployment environment identifier (snc1, dub1, sac1) | yes | none | env / helm |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `daemon.coord_worker.active` | Enables or disables the Coordination Worker daemon | `true` | global |
| `daemon.dispatcher.active` | Enables or disables the Dispatcher daemon | `true` | global |
| `daemon.user_sync.active` | Enables or disables the User Sync daemon | `true` | global |
| `daemon.queue_monitor.active` | Enables or disables the Queue Monitor daemon | `true` | global |
| `daemon.error_listener.active` | Enables or disables the Error Listener daemon | `true` | global |
| `daemon.subscription_listener.active` | Enables or disables the Subscription Listener daemon | `true` | global |
| `circuit_breaker.cas.enabled` | Enables circuit breaker on CAS arbitration calls | `true` | global |
| `circuit_breaker.campaign_mgmt.enabled` | Enables circuit breaker on Campaign Management API calls | `true` | global |

These flags are stored in `continuumInboxManagementPostgres` and managed via the `/im/admin/config/{key}` endpoint.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `application.conf` | HOCON (typesafe-config) | Primary application config — Kafka topics, thread pool sizes, retry parameters, timeout values |
| `logback.xml` | XML | Logback/Steno structured logging configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `inbox-management-postgres-credentials` | PostgreSQL username and password | k8s-secret |
| `inbox-management-edw-credentials` | EDW/Hive username and password | k8s-secret |
| `inbox-management-kafka-credentials` | Kafka client authentication credentials (if applicable) | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **snc1** (US production): Full-scale sharded Redis, production Postgres, production EDW; all daemons active; full throttle limits enforced.
- **dub1** (EU production): Same configuration as snc1 with EU-region Redis and Postgres endpoints; may have separate Kafka cluster.
- **sac1** (US secondary / DR): Standby configuration; daemon active flags may be toggled off during normal operations.
- **Staging/Dev**: Reduced shard counts, lower throttle rates, test Kafka topics; EDW access may use a staging replica.

Runtime config keys in Postgres allow region-specific throttle and circuit breaker tuning without redeployment.
