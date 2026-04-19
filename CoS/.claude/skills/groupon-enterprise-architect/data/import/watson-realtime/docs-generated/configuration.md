---
service: "watson-realtime"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars]
---

# Configuration

## Overview

watson-realtime workers are configured through environment variables injected at container startup. Each worker is a separate deployable unit and carries its own configuration for Kafka broker addresses, consumer group IDs, target store connection strings, and AWS credentials for Keyspaces access. No configuration service (Consul, Vault) or feature flag system was discoverable from the architecture model. Specific variable names are not surfaced in the architecture DSL; the variables documented below are derived from the libraries and integration patterns described in the inventory.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka broker connection string for all workers | yes | none | env |
| `KAFKA_APPLICATION_ID` | Kafka Streams application ID (consumer group prefix) per worker | yes | none | env |
| `KAFKA_CONSUMER_GROUP` | Consumer group ID override (if separate from application ID) | no | derived from application ID | env |
| `REDIS_HOST` | Redis host for `raasRedis_3a1f` connection | yes | none | env |
| `REDIS_PORT` | Redis port | yes | 6379 | env |
| `REDIS_PASSWORD` | Redis AUTH credential | yes | none | env |
| `CASSANDRA_CONTACT_POINTS` | Cassandra/Keyspaces endpoint(s) | yes (analytics-ks, ks-table-trimmer) | none | env |
| `CASSANDRA_KEYSPACE` | Target Cassandra keyspace name | yes (analytics-ks, ks-table-trimmer) | none | env |
| `AWS_ACCESS_KEY_ID` | AWS access key for SigV4 signing against Amazon Keyspaces | yes (analytics-ks, ks-table-trimmer) | none | env |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for SigV4 signing | yes (analytics-ks, ks-table-trimmer) | none | env |
| `AWS_REGION` | AWS region for Keyspaces endpoint | yes (analytics-ks, ks-table-trimmer) | none | env |
| `POSTGRES_JDBC_URL` | JDBC connection URL for `postgresCookiesDb_2f7a` | yes (cookies) | none | env |
| `POSTGRES_USER` | PostgreSQL username | yes (cookies) | none | env |
| `POSTGRES_PASSWORD` | PostgreSQL password | yes (cookies) | none | env |
| `JANUS_METADATA_SERVICE_URL` | Base URL for `janusMetadataService_4d1e` HTTP calls | yes (cookies, dealview, realtime-kv, rvd, user-identities) | none | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are shown here.

## Feature Flags

> No evidence found

No feature flag system or runtime flag configuration was discoverable from the architecture model.

## Config Files

> No evidence found

No config files (YAML, properties, TOML) were discoverable from the architecture model. Configuration is expected to be entirely environment-variable-driven.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Redis password | Authenticates the Jedis connection to `raasRedis_3a1f` | Not discoverable — likely k8s-secret or AWS Secrets Manager |
| PostgreSQL password | Authenticates JDBC connection to `postgresCookiesDb_2f7a` | Not discoverable — likely k8s-secret or AWS Secrets Manager |
| AWS access key / secret key | Provides SigV4 signing credentials for Amazon Keyspaces access | Not discoverable — likely k8s-secret or IAM role |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Each environment (dev, staging, production) will differ in Kafka broker addresses, Redis endpoints, Cassandra/Keyspaces endpoints and keyspace names, PostgreSQL connection URLs, and AWS region/credentials. The service itself contains no environment-specific logic — all differences are expressed through the environment variable values injected at deployment time. Deployment configuration is managed externally (see [Deployment](deployment.md)).
