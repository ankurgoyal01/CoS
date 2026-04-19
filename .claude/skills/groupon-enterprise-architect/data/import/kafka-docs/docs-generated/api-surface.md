---
service: "kafka-docs"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [kafka-binary, zookeeper]
auth_mechanisms: [tls, plaintext]
---

# API Surface

## Overview

The `kafka-docs` documentation site itself has no HTTP API — it is a static site consumed by browsers. However, the Kafka platform documented here exposes a binary Kafka protocol over TCP on port 9092 (plaintext) and port 9094 (TLS for MSK cloud). ZooKeeper is exposed on port 2181 for legacy client use. The documentation catalogs all broker and ZooKeeper endpoints across all colos and environments.

## Endpoints

### On-Premises Broker Endpoints (Kafka binary protocol, port 9092)

| Type | Environment | COLO | Kafka Version | Endpoint |
|------|-------------|------|---------------|----------|
| Local | Production | SNC1 | 0.10.2.1 | `kafka.snc1:9092` |
| Aggregate | Production | SNC1 | 0.10.2.1 | `kafka-aggregate.snc1:9092` |
| Local | Production | SAC1 | 0.10.2.1 | `kafka-broker-lb.sac1:9092` |
| Aggregate | Production | SAC1 | 0.10.2.1 | `kafka-aggregate.sac1:9092` |
| Local | Production | DUB1 | 0.10.2.1 | `kafka.dub1:9092` |
| Local | Staging | SNC1 | 0.10.2.1 | `kafka-08-broker-staging-vip.snc1:9092` |
| Aggregate | Staging | SNC1 | 0.10.2.1 | `kafka-aggregate-staging.snc1:9092` |
| Local | Development | SNC1 | 0.10.2.1 | `kafka-08-broker-dev-vip.snc1:9092` |
| Aggregate | UAT | SNC1 | 0.10.2.1 | `kafka-aggregate-broker-uat.snc1:9092` |

### AWS MSK Cloud Endpoints

| Cluster | Environment | Kafka Version | Endpoint | Protocol |
|---------|-------------|---------------|----------|----------|
| kafka-grpn-gensandbox | gensandbox/dev (us-west-2) | 2.3.1 | `kafka-grpn.gensandbox.us-west-2.aws.groupondev.com:9092` | Plaintext |
| kafka-grpn-dev | grpn-dse-dev (us-west-2) | 2.2.1 | `kafka-grpn-producer.grpn-dse-dev.us-west-2.aws.groupondev.com:9094` (producer) | TLS |
| kafka-grpn-dev | grpn-dse-dev (us-west-2) | 2.2.1 | `kafka-grpn-consumer.grpn-dse-dev.us-west-2.aws.groupondev.com:9094` (consumer) | TLS |
| kafka-metrics-dev | grpn-dse-dev (us-west-2) | 2.6.0 | `kafka-metrics-producer.grpn-dse-dev.us-west-2.aws.groupondev.com:9094` (producer) | TLS |
| kafka-metrics-dev | grpn-dse-dev (us-west-2) | 2.6.0 | `kafka-metrics-consumer.grpn-dse-dev.us-west-2.aws.groupondev.com:9094` (consumer) | TLS |

### ZooKeeper Endpoints (legacy use only, port 2181)

| COLO | Type | Environment | Endpoint |
|------|------|-------------|----------|
| SNC1 | Local | Production | `kafka-zk.snc1:2181` |
| SNC1 | Aggregate | Production | `kafka-aggregate-zk.snc1:2181` |
| SAC1 | Local | Production | `kafka-zk.sac1:2181` |
| SAC1 | Aggregate | Production | `kafka-aggregate-zk.sac1:2181` |
| DUB1 | Local | Production | `kafka-zk.dub1:2181` |
| SNC1 | Local | Staging | `kafka-08-broker-staging-zk-vip.snc1:2181` |
| SNC1 | Aggregate | Staging | `kafka-aggregate-zk-staging.snc1:2181` |
| SNC1 | Local | Development | `kafka-08-broker-dev-vip.snc1:2181` |
| SNC1 | Aggregate | UAT | `kafka-aggregate-zk-uat.snc1:2181` |

## Request/Response Patterns

### Connection configuration

- **Modern clients (0.9+)**: Use `bootstrap.servers` config to specify broker endpoints.
- **Legacy clients (0.8)**: Use `metadata.broker.list` config instead.
- **ZooKeeper**: Use `zookeeper.connect` config — only required for legacy 0.8 consumers storing offsets in ZooKeeper; not supported in cloud environments.
- All clients must set a unique `client.id` to identify traffic by team, application, and data stream.

### Relative domain name behavior

Using a relative domain (e.g., `kafka:9092` instead of `kafka.snc1:9092`) causes resolution to the local colo's Kafka cluster. Exception: SAC1 `kafka.sac1` remains a CNAME for `kafka.snc1` until all consumers migrate to Hydra-compliant architectures.

### Error format

> No evidence found in codebase. Kafka binary protocol errors are defined by the Apache Kafka protocol specification.

### Pagination

> Not applicable. Kafka uses offset-based sequential consumption, not HTTP pagination.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| Per-client quota | Configurable via Kafka broker `quotas` | Per-second byte/request rate |

Rate limiting is enforced via Kafka's built-in quota mechanism. Teams with unthrottled producers or consumers can request quotas to be set by the Data Systems team via a Kafka Support Request.

## Versioning

The documented Kafka version running on on-prem clusters is **0.10.2.1**. AWS MSK clusters run **2.2.1 – 2.6.0** depending on the cluster. Client library version compatibility follows the Apache Kafka backward-compatibility guarantees. Auto-topic creation is disabled on production and aggregate clusters; it is enabled on development and gensandbox clusters.

## OpenAPI / Schema References

> Not applicable. Kafka uses a binary protocol, not REST. Client message schema registration is handled by the `kafka-message-serde` library at `https://github.groupondev.com/data/kafka-message-serde`.
