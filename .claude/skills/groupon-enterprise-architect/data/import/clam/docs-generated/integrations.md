---
service: "clam"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 1
---

# Integrations

## Overview

CLAM has four external runtime dependencies: two Kafka topics (input and output), an HDFS cluster for checkpoint storage, and a Metrics Gateway for operational self-reporting. It has one internal Groupon dependency: the `metrics-sma-influxdb` library from the JTier platform. There are no REST or gRPC service-to-service calls.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Kafka broker cluster | Kafka (port 9092) | Source of histogram events (input topic) and sink for aggregate measurements (output topic) | yes | `unknownKafkaBrokerCluster_4f18a9b2` (stub) |
| HDFS (gdoop) | HDFS filesystem | Spark Structured Streaming checkpoint and group state persistence | yes | `unknownSparkCheckpointStore_8af4b0ce` (stub) |
| Metrics Gateway | HTTP (InfluxDB line protocol) | Operational self-metrics — processing time, input count, bad-data count, heartbeat | no | `unknownMetricsGatewayEndpoint_18b7c61a` (stub) |
| Nexus artifact repository | HTTP | Artifact download during deployment (release tarball) | no | Not modelled |

### Kafka Broker Cluster Detail

- **Protocol**: Kafka binary protocol (port 9092)
- **Base URL**: Per environment — `kafka.snc1:9092` (prod-snc), `kafka-broker-lb.sac1:9092` (prod-sac), `kafka.dub1:9092` (prod-dub), `kafka-08-broker-staging-vip.snc1:9092` (staging/local)
- **Auth**: No authentication configured (internal Kafka cluster)
- **Client ID**: `spark_metrics_clam`
- **Purpose**: CLAM subscribes to the input histogram topic and publishes aggregated records to the output topic. Kafka is the sole data ingress and egress mechanism.
- **Failure mode**: If the Kafka broker is unreachable, the Spark streaming query fails with a `StreamingQueryException`; the YARN job exits and gdoop-cron restarts it on the next scheduled cron tick (every minute).
- **Circuit breaker**: No evidence found in codebase.

### HDFS (gdoop) Detail

- **Protocol**: HDFS filesystem API (via Spark Hadoop integration)
- **Base URL**: Configured via Spark YARN cluster defaults; checkpoint paths are `/user/grp_gdoop_metrics/clam_spark_app/checkpoint/` (production) and `spark-checkpoint/` (local)
- **Auth**: Runs as YARN user `svc_clam`; HDFS permissions managed via YARN/Kerberos cluster defaults
- **Purpose**: Durable checkpoint storage for Spark Structured Streaming — stores committed Kafka offsets and serialised TDigest group state so the job can restart without data loss.
- **Failure mode**: If HDFS is unavailable at startup, the Spark job fails to initialise. If HDFS becomes unavailable during a checkpoint write, Spark retries internally before failing the query.
- **Circuit breaker**: No evidence found in codebase. Spark has built-in retry logic for HDFS writes.

### Metrics Gateway Detail

- **Protocol**: HTTP with InfluxDB line protocol payload
- **Base URL**: `http://localhost:8186` (prod — sidecar pattern); `http://metrics-gateway-staging-vip.snc1:80/` (staging/local)
- **Auth**: None (internal endpoint)
- **Purpose**: Receives CLAM's operational self-metrics — Spark job processing time, input row counts, speculative task counts, bad-data counts, and heartbeat signals. Metrics are submitted via `MetricsSubmitter` from the `metrics-sma-influxdb` library under the namespace `custom.clam`.
- **Failure mode**: Self-metric submission failures are non-critical; the streaming pipeline continues.
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `metrics-sma-influxdb` (JTier metrics library) | in-process library | Provides `MetricsSubmitter`, `ConfiguredInfluxWriter`, and `ImmutableMeasurement` abstractions for self-metric publishing | Not separately modelled |

## Consumed By

> Upstream consumers are tracked in the central architecture model. CLAM publishes to `metrics_aggregates` / `aggregates` Kafka topics; consumers of those topics are not discoverable from this repository.

## Dependency Health

- **Kafka**: CLAM does not implement custom circuit-breaking or retry beyond Spark's native Kafka connector retry behaviour. A Kafka failure causes the YARN job to terminate and be restarted by gdoop-cron.
- **HDFS**: Spark's checkpoint mechanism includes internal retry. Manual recovery requires clearing the checkpoint path via `hdfs dfs -rm -r` and redeploying.
- **Metrics Gateway**: Non-critical dependency. The streaming pipeline is not gated on successful self-metric submission.
