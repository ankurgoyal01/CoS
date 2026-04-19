---
service: "mirror-maker-kubernetes"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 2
---

# Integrations

## Overview

MirrorMaker Kubernetes integrates with four external infrastructure systems: two Kafka cluster endpoints per pod (source and destination, which may be the same cluster type in different environments), a metrics pipeline, and a log aggregation pipeline. All integrations are outbound-only. The service has no inbound integration surface. Across the full deployment portfolio, the broker pairs span K8s-native Kafka, AWS MSK, and GCP Kafka.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Source Kafka Cluster | Kafka (TCP, mTLS or plaintext) | Consumes whitelisted topic records for replication | yes | `continuumKafkaBroker` |
| Destination Kafka Cluster | Kafka (TCP, mTLS or plaintext) | Publishes replicated records to destination topics | yes | `continuumKafkaBroker` |
| InfluxDB (via Telegraf/TELEGRAF_URL) | HTTP (InfluxDB line protocol) | Receives Jolokia-scraped JMX metrics | no | `metricsStack` |
| Logging Stack (via Filebeat) | Filebeat / Elasticsearch protocol | Receives pod log streams from `/var/log/mirror-maker/mirror-maker.log` | no | `loggingStack` |

### Source Kafka Cluster Detail

- **Protocol**: Kafka native protocol, port 9093 (mTLS) or 9094 (plaintext/one-way TLS); controlled by `SOURCE_USE_MTLS`
- **Base URL / SDK**: Configured via `SOURCE` env var (e.g., `kafka-grpn-kafka-bootstrap.kafka-production.svc.cluster.local:9093` for K8s-native; `kafka-grpn-consumer.grpn-dse-prod.eu-west-1.aws.groupondev.com:9094` for MSK; `kafka-grpn.us-central1.kafka.prod.gcp.groupondev.com:9094` for GCP)
- **Auth**: mTLS when `SOURCE_USE_MTLS=true`; client certificate from `/var/groupon/certs` volume mount
- **Purpose**: Supplies the records to be mirrored to the destination cluster
- **Failure mode**: Replication halts; consumer lag accumulates on source; Jolokia lag metric will alert; pod stays running but produces no output
- **Circuit breaker**: None configured; MirrorMaker retries Kafka client connections natively

### Destination Kafka Cluster Detail

- **Protocol**: Kafka native protocol, port 9093 (mTLS) or 9094 (plaintext/one-way TLS); controlled by `DESTINATION_USE_MTLS`
- **Base URL / SDK**: Configured via `DESTINATION` env var (e.g., `kafka-grpn-consumer.grpn-dse-prod.eu-west-1.aws.groupondev.com:9094` for MSK; `kafka-grpn-kafka-bootstrap.kafka-production.svc.cluster.local:9093` for K8s-native)
- **Auth**: mTLS when `DESTINATION_USE_MTLS=true`; client certificate from `/var/groupon/certs` volume mount
- **Purpose**: Receives replicated records on prefixed or renamed topics
- **Failure mode**: Producer records are buffered to `BATCH_SIZE` limit; excess records are dropped and counted in `MirrorMaker-numDroppedMessages` JMX metric
- **Circuit breaker**: None configured

### InfluxDB (Metrics) Detail

- **Protocol**: HTTP to `$TELEGRAF_URL`
- **Base URL / SDK**: Resolved at runtime from `TELEGRAF_URL` env var (injected by Helm chart)
- **Auth**: Internal network only; no auth configured in Telegraf config
- **Purpose**: Stores consumer lag, byte rates, record send rates, drop counts for operational alerting and dashboards
- **Failure mode**: Metrics go unreported; replication itself is unaffected
- **Circuit breaker**: No

### Logging Stack (Filebeat) Detail

- **Protocol**: Filebeat output (Elasticsearch-compatible)
- **Base URL / SDK**: Configured via Filebeat sidecar (injected by Helm chart, `filebeatMsk: true`)
- **Auth**: Internal cluster network
- **Purpose**: Centralizes pod log output (`/var/log/mirror-maker/mirror-maker.log`, `sourceType: mirror_maker`) for search and alerting
- **Failure mode**: Logs are lost (no local retention beyond pod lifetime); replication is unaffected
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Kafka Platform Infrastructure | Kafka native | Provides the source and destination broker cluster endpoints | `continuumKafkaBroker` |
| Metrics Platform (metricsStack) | HTTP/InfluxDB | Receives Telegraf-forwarded JMX metrics | `metricsStack` |
| Logging Platform (loggingStack) | Filebeat | Receives aggregated pod logs | `loggingStack` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Downstream consumers of the mirrored topics are domain-specific Kafka consumer services that read from the destination cluster using the prefixed topic names (e.g., `k8s.janus-all_snc1`, `msk.janus-tier1`).

## Dependency Health

- Source/destination broker connectivity is verified at startup by the MirrorMaker Kafka client initialization; pod fails to start if brokers are unreachable.
- Readiness and liveness probes use `pgrep java` (delay 20s/30s, period 5s/15s) — a JVM process presence check rather than a functional connectivity check.
- No circuit breaker or retry cap is configured beyond Kafka client built-in reconnect behavior.
