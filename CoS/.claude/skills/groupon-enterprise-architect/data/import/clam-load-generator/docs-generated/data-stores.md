---
service: "clam-load-generator"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "telegraf-http"
    type: "influxdb-compatible-http"
    purpose: "write-target for load generation (telegraf and sma modes)"
---

# Data Stores

## Overview

The CLAM Load Generator does not own any persistent data stores. It is a stateless batch-execution service. All metric data it produces is written directly to external backends (Kafka topic, Telegraf HTTP listener, or jtier SMA writer) and is not stored or managed by this service. The service reads back metric data from Wavefront during verification phases but does not persist those results.

## Stores

> This service is stateless and does not own any data stores.

The following external write targets are used transiently during load generation:

| Target | Protocol | Mode | Config Property |
|--------|----------|------|----------------|
| Telegraf HTTP listener | InfluxDB line-protocol over HTTP | `telegraf` and `sma` test-target modes | `telegraf.url` |
| Apache Kafka topic | Kafka producer protocol | `kafka` test-target mode | `kafka.broker-address`, `kafka.topic` |
| Wavefront Query API | REST/HTTP (read-only, verification only) | All modes with verification enabled | `aggregation.wavefrontUrl` |
| Metrics gateway | InfluxDB line-protocol over HTTP (verification only) | Gateway integration verification | `aggregation.gatewayUrl` |

## Caches

> No evidence found in codebase. No caching layer is used.

## Data Flows

All data flows are outbound and ephemeral:

1. **Kafka mode**: `MetricLineFactory` generates `Line` objects in memory → `PartitionSender` serializes to JSON → `KafkaTemplate` publishes to the `histograms_v2` topic on the configured `kafka.broker-address`.
2. **Telegraf mode**: `PartitionService` generates InfluxDB `Point` objects in memory → `InfluxDB.write()` sends via HTTP to `telegraf.url` with optional batch buffering.
3. **SMA mode**: `SmaMetricFactory` creates `ImmutableMeasurement` batches in memory → `MetricsSubmitter` submits to `BufferingInfluxWriter` → buffered writes are flushed via HTTP to `telegraf.url` using OkHttp3.
4. **Verification read-back**: `WavefrontVerifier` queries `GET /api/v2/chart/raw` on `aggregation.wavefrontUrl` using a Bearer token and compares returned `RawTimeseries` points against configured `aggregation.dataExpectations`.
