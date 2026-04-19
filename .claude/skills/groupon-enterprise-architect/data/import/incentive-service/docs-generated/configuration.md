---
service: "incentive-service"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, helm-values]
---

# Configuration

## Overview

The Incentive Service is configured entirely via environment variables injected at runtime by Kubernetes. The `SERVICE_MODE` variable is the primary operational switch, controlling which subsystems activate on startup. Secrets (database credentials, messaging credentials) are expected to be injected from a secrets store (Kubernetes secrets or equivalent) rather than hardcoded. Feature flags are managed via the Keldor feature flag system.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DEPLOY_ENV` | Deployment environment identifier (development/staging/production) | yes | — | env |
| `SERVICE_MODE` | Activates the appropriate subsystem: `batch`, `messaging`, `checkout`, `bulk`, or `admin` | yes | — | env |
| `PORT` | HTTP server listen port | no | `9000` | env |
| `LOG_LEVEL` | Logging verbosity: `debug`, `info`, `warn`, `error` | no | `info` | env |
| `DB_URL` | PostgreSQL JDBC connection URL | yes | — | env / k8s-secret |
| `DB_USER` | PostgreSQL username | yes | — | env / k8s-secret |
| `DB_PASSWORD` | PostgreSQL password | yes | — | env / k8s-secret |
| `CASSANDRA_HOSTS` | Comma-separated Cassandra contact points | yes (on-prem) | — | env |
| `CASSANDRA_KEYSPACE` | Cassandra keyspace name | yes (on-prem) | — | env |
| `REDIS_URL` | Redis connection URL | yes | — | env |
| `REDIS_PASSWORD` | Redis authentication password | yes (if auth enabled) | — | env / k8s-secret |
| `BIGTABLE_PROJECT_ID` | Google Cloud project ID for Bigtable | yes (cloud) | — | env |
| `BIGTABLE_INSTANCE_ID` | Bigtable instance ID | yes (cloud) | — | env |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka broker connection string | yes | — | env |
| `KAFKA_GROUP_ID` | Kafka consumer group identifier | yes | — | env |
| `MBUS_URL` | MBus/STOMP broker URL | yes | — | env |
| `MBUS_USERNAME` | MBus authentication username | yes | — | env / k8s-secret |
| `MBUS_PASSWORD` | MBus authentication password | yes | — | env / k8s-secret |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

Feature flags are managed by Keldor (Groupon's internal feature flag system).

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `incentive.newQualificationEngine` | Enable the revised audience qualification algorithm | off | global |
| `incentive.bulkExportV2` | Use the new bulk export CSV format | off | global |
| `incentive.realtimeAudience` | Enable Realtime Audience Management Service (RTAMS) integration | off | global |
| `incentive.campaignApprovalWorkflow` | Enable the multi-step campaign approval workflow | off | global |

## Config Files

> No evidence found in codebase. Play Framework application configuration is expected in `conf/application.conf` following standard Play conventions, with environment-specific overrides via environment variables.

| File | Format | Purpose |
|------|--------|---------|
| `conf/application.conf` | HOCON | Play Framework application configuration (routes, module bindings, DB pool settings) |
| `conf/routes` | Play routes DSL | HTTP route definitions mapping paths to controllers |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_PASSWORD` | PostgreSQL authentication | k8s-secret |
| `REDIS_PASSWORD` | Redis authentication | k8s-secret |
| `MBUS_PASSWORD` | MBus/STOMP broker authentication | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies are listed.

## Per-Environment Overrides

- **development**: `DEPLOY_ENV=development`; local databases; `LOG_LEVEL=debug`; feature flags generally enabled for testing
- **staging**: `DEPLOY_ENV=staging`; staging database instances; mirrors production topology; used for pre-production validation
- **production**: `DEPLOY_ENV=production`; production credentials injected via Kubernetes secrets; `LOG_LEVEL=info`; feature flags controlled via Keldor; deployed across regions `snc1`, `sac1`, `dub1`, and GCP cloud
- **cloud environments**: Use `continuumIncentiveKeyspaces` (Amazon Keyspaces) instead of `continuumIncentiveCassandra`; `BIGTABLE_PROJECT_ID` and `BIGTABLE_INSTANCE_ID` required
