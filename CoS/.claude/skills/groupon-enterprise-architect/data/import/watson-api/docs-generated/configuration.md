---
service: "watson-api"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

Watson API is configured through a combination of Dropwizard YAML configuration files (injected at deploy time by the JTier platform), environment variables (both plain and secret), and Kubernetes deployment YAML overlays managed in `.meta/deployment/cloud/`. The active deployment component is selected at runtime via the `DEPLOY_COMPONENT` environment variable, which causes the application to register only the resource classes appropriate for that component. This single-image, multi-component deployment model means each pod has a distinct configuration profile.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DEPLOY_COMPONENT` | Selects which service component to activate (`dealkv`, `userkv`, `emailfreshness`, `rvd`, `janusaggregation`, `useridentities`, `analytics`) | yes | none | env |
| `KAFKA_TLS_ENABLED` | Enables SSL transport for the Kafka producer | no | unset (disabled) | env |
| `KAFKA_MTLS_ENABLED` | Enables mTLS for the Kafka producer (requires `KAFKA_TLS_ENABLED=true`) | no | unset (disabled) | env |
| `JKS_MSK_PASSWORD` | Password for the JKS keystore used for Kafka SSL/mTLS | if TLS enabled | none | env (secret) |
| `MALLOC_ARENA_MAX` | Limits malloc arena count to prevent virtual memory explosion in containers | no | `4` (set in component YAMLs) | env |

## Feature Flags

> No evidence found in codebase. No feature flag framework is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/{component}/common.yml` | YAML | Per-component Kubernetes deployment defaults (replicas, ports, resources, APM) |
| `.meta/deployment/cloud/components/{component}/{env}-{region}.yml` | YAML | Per-environment and per-region overrides for each component |
| `src/main/resources/hbase-site.xml` | XML | HBase client configuration (ZooKeeper quorum, cluster settings, timeouts) |
| JTier service YAML (injected at deploy) | YAML | Dropwizard application configuration: `redis`, `rvdRedis`, `janusRedis`, `kafka`, `cassandra`, `postgres` sections |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `JKS_MSK_PASSWORD` | Kafka JKS keystore password for SSL/mTLS authentication | env (injected by JTier platform secrets) |
| PostgreSQL credentials | DaaS-managed database password for Janus PostgreSQL | JTier DaaS secrets |
| Cassandra AWS credentials | IAM role credentials for Amazon Keyspaces SigV4 auth | AWS STS / IAM role |
| Redis TLS client certificates | TLS client cert/key for Redis mTLS | Kubernetes volume mount at `/var/groupon/certs` |

> Secret values are NEVER documented. Only names and rotation policies.

## Redis Configuration Schema (from `RedisConfig`)

| Config Key | Purpose |
|------------|---------|
| `redis.protocol` | Redis topology: `CLUSTER` or `STANDALONE` |
| `redis.connectionTimeout` | Connection timeout in milliseconds |
| `redis.hostPorts[].host` | Redis host |
| `redis.hostPorts[].port` | Redis port |
| `redis.hostPorts[].numberOfConnection` | Number of connections per host |

The `rvdRedis` config accepts a list of two `RedisConfig` entries — index 0 is used for deal KV data, index 1 for deal-and-purchase data in the RVD component.

## Cassandra Configuration Schema (from `CassandraConfig`)

| Config Key | Purpose |
|------------|---------|
| `cassandra.clusterName` | Cassandra cluster name |
| `cassandra.dataCenter` | Target data center for local policy |
| `cassandra.keySpace` | Legacy keyspace name |
| `cassandra.newKeySpace` | Current active keyspace |
| `cassandra.port` | Legacy port |
| `cassandra.newPort` | Current active port |
| `cassandra.seeds` | Seed node host set |
| `cassandra.endPoint` | Amazon Keyspaces endpoint |
| `cassandra.region` | AWS region for SigV4 auth |
| `cassandra.maxReadWaitInSecs` | Read timeout |
| `cassandra.keyStoreFile` | Path to JKS keystore for Cassandra TLS |

## Kafka Configuration Schema (from `KafkaConfig`)

| Config Key | Purpose |
|------------|---------|
| `kafka.bootstrapServer` | Kafka broker connection string |
| `kafka.topic` | Target topic for `RealtimeKvEvent` records |
| `kafka.deliveryTimeoutMs` | Max delivery timeout |
| `kafka.requestTimeoutMs` | Per-request timeout |
| `kafka.retries` | Retry count on failure |
| `kafka.lingerMs` | Batch linger time |
| `kafka.maxBlockMs` | Max block time on full buffer |
| `kafka.ackType` | Producer acknowledgement mode |
| `kafka.batchSize` | Batch size in bytes |
| `kafka.compressionType` | Compression algorithm |
| `kafka.maxRequestSize` | Maximum request size |
| `kafka.maxInFlightRequest` | Max in-flight requests per connection |
| `kafka.metadataMaxAgeMs` | Metadata refresh interval |
| `kafka.keyStoreFile` | JKS keystore path for SSL |

## Per-Environment Overrides

Each deployment component has environment- and region-specific YAML files in `.meta/deployment/cloud/components/{component}/`. The `common.yml` sets defaults; overlays such as `staging-us-central1.yml` or `production-eu-west-1.yml` can override replica counts, resource limits, or environment-specific configuration. Kustomize overlays in `overlays/` directories (present for `analytics` and `janus-aggregation` components) apply Kubernetes-level patches such as egress network policies and IAM role environment variable bindings.

**Scaling per component:**

| Component | Min Replicas | Max Replicas | HPA Target Utilization |
|-----------|-------------|-------------|----------------------|
| `analytics` | 3 | 15 | 50% |
| `dealkv` | 1 | 12 | 50% |
| `emailfreshness` | 1 | 12 | 50% |
| `janusaggregation` | 3 | 15 | 50% |
| `rvd` | 3 | 15 | 50% |
| `userkv` | 1 | 12 | 50% |
| `useridentities` | 1 | 15 | 50% |
