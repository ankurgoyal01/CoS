---
service: "ams"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

AMS follows the Dropwizard/JTier configuration pattern: a YAML config file is loaded at startup and merged with environment variable overrides. Secrets (database credentials, Kafka broker addresses, GCP credentials, AWS signing keys) are injected at runtime via environment. Flyway migrations run automatically on startup using the configured MySQL connection.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | MySQL JDBC connection URL for `continuumAudienceManagementDatabase` | yes | None | env |
| `DATABASE_USER` | MySQL username | yes | None | env |
| `DATABASE_PASSWORD` | MySQL password | yes | None | env |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka broker addresses for `audience_ams_pa_create` publisher | yes | None | env |
| `BIGTABLE_PROJECT_ID` | GCP project ID for Bigtable cluster access | yes | None | env |
| `BIGTABLE_INSTANCE_ID` | Bigtable instance identifier | yes | None | env |
| `CASSANDRA_CONTACT_POINTS` | Cassandra node contact points | yes | None | env |
| `CASSANDRA_KEYSPACE` | Cassandra keyspace for audience records | yes | None | env |
| `REDIS_URL` | Redis connection URL for Lettuce client | yes | None | env |
| `LIVY_GATEWAY_URL` | Base URL for Livy Gateway REST API | yes | None | env |
| `YARN_RESOURCE_MANAGER_URL` | YARN resource manager URL for job monitoring | yes | None | env |
| `AWS_ACCESS_KEY_ID` | AWS access key for SigV4 signing | yes | None | env |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for SigV4 signing | yes | None | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found for named feature flags in the repository inventory. Contact the Audience Service / CRM team for runtime flag configuration.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config.yml` (Dropwizard standard) | YAML | Primary service configuration: server settings, database pool, logging, Kafka, Bigtable, Cassandra, Redis, Livy connection parameters |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DATABASE_PASSWORD` | MySQL authentication credential | env / secrets manager |
| `AWS_SECRET_ACCESS_KEY` | AWS SigV4 signing key | env / secrets manager |
| `CASSANDRA_PASSWORD` | Cassandra authentication credential | env / secrets manager |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Environment-specific values (database hosts, Kafka cluster endpoints, Bigtable/Cassandra contact points, Livy Gateway URLs) are injected via environment variables at deploy time. The YAML config file provides structural defaults; environment-specific secrets and service URLs override them at runtime. Flyway migrations are environment-aware and apply pending changes automatically on startup.
