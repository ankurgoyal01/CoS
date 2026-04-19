---
service: "clam-load-generator"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The CLAM Load Generator is configured exclusively through Spring Boot YAML profile files located in `src/main/resources/`. The active profile is selected at startup via `--spring.profiles.active=<profile-name>`. A custom config file can also be supplied with `--spring.config.additional-location=file:./custom-config.yml`. One environment variable (`TARGET_URL`) is referenced by several profiles. All other values are baked into the profile YAML files bundled in the JAR.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `TARGET_URL` | Base URL of the Telegraf HTTP listener to write metric points to (e.g., `http://telegraf-agent1-uat.snc1:8186/`) | Yes (for `telegraf` and `sma` modes) | None | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `test-target` | Selects the active load generation strategy: `kafka`, `telegraf`, or `sma` | None (must be set) | per-profile |
| `wiremock.enabled` | Enables the local WireMock HTTP server on port 2345 as a Telegraf mock | `false` | per-profile |
| `sma.short-names-enabled` | Use short metric names in SMA mode | `false` | per-profile |
| `sma.t-digest-enabled` | Enable T-Digest compression encoding for SMA metrics | `false` (`true` in `sma-load-test`) | per-profile |
| `sma.wavefront-enabled` | Enable direct Wavefront metric submission from SMA strategy | `false` | per-profile |
| `metrics.send-to-wavefront` | Enable direct Wavefront forwarding from metric generator | `false` | per-profile |
| `telegraf.influxDb.batch-enabled` | Enable InfluxDB batch write mode with configurable batch/flush settings | `false` | per-profile |
| `jtier-metrics.metricsWriter.emitInternalTelemetry` | Emit jtier internal telemetry metrics alongside SMA metrics | `false` | per-profile |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/application-sma-load-test.yml` | YAML | SMA load test: 20 threads, 5M ops, 8333 ops/sec, 10-minute timeout; T-Digest enabled; buffered InfluxDB writes |
| `src/main/resources/application-kafka-minimal.yml` | YAML | Kafka minimal test: `histograms_v2` topic, staging broker, 30 shared metrics, JSON mode |
| `src/main/resources/application-kafka-case1.yml` | YAML | Kafka case-1 scenario test |
| `src/main/resources/application-kafka-bugged-key.yml` | YAML | Kafka scenario testing bugged key routing |
| `src/main/resources/application-kafka-one-service-partition.yml` | YAML | Kafka test with a single service/partition |
| `src/main/resources/application-kafka-partition-underrun.yml` | YAML | Kafka partition underrun scenario |
| `src/main/resources/application-kafka-prod-dub-break.yml` | YAML | Kafka production Dublin break scenario |
| `src/main/resources/application-kafka-stg-break.yml` | YAML | Kafka staging break scenario |
| `src/main/resources/application-telegraf-load-test.yml` | YAML | Telegraf load test: 5 threads, 5M ops, 20K ops/sec, 10-minute timeout; batched writes |
| `src/main/resources/application-telegraf-integration.yml` | YAML | Telegraf integration test: 1 thread, 20 ops, 5 ops/sec |
| `src/main/resources/application-telegraf-integration.yml` | YAML | Telegraf aggregation integration test (variant) |
| `src/main/resources/application-telegraf-aggregation-verify0.yml` | YAML | Telegraf aggregation verification scenario 0 |
| `src/main/resources/application-telegraf-aggregation-verify1.yml` | YAML | Telegraf aggregation verification scenario 1 |
| `src/main/resources/application-telegraf-gateway-integration.yml` | YAML | Gateway integration verification: 5 threads, 20 ops |
| `src/main/resources/application-jtier-load-test.yml` | YAML | JTier InfluxDB load test profile |
| `src/main/resources/application-jtier-wiremock-load-test.yml` | YAML | JTier load test with WireMock replacing Telegraf |
| `src/main/resources/application-dummy-test.yml` | YAML | Dummy no-op test using `DummyLoadGenerationStrategy` |
| `src/main/resources/application-operator-telegraf.yml` | YAML | Operator Telegraf profile |
| `src/main/resources/application-clam-deploy-baseline.yml` | YAML | CLAM deployment baseline verification profile |

## Configuration Property Reference

### `generator.*` — Load orchestration

| Property | Purpose | Example Value |
|----------|---------|---------------|
| `generator.threads` | Number of concurrent worker threads | `20` |
| `generator.max-operations` | Maximum number of operations before stopping | `5000000` |
| `generator.rate-per-second` | Target throughput via Guava `RateLimiter` | `8333` |
| `generator.timeout` | Maximum run duration (ISO 8601 duration) | `PT10M` |

### `kafka.*` — Kafka producer (active when `test-target=kafka`)

| Property | Purpose | Example Value |
|----------|---------|---------------|
| `kafka.broker-address` | Kafka bootstrap server address | `kafka-08-broker-staging-vip.snc1:9092` |
| `kafka.topic` | Target Kafka topic | `histograms_v2` |
| `kafka.client-id` | Kafka producer client ID (set to `disabled` to omit) | `telegraf_metrics_gateway` |

### `telegraf.*` — InfluxDB/Telegraf write client

| Property | Purpose | Example Value |
|----------|---------|---------------|
| `telegraf.url` | Telegraf HTTP listener base URL | `${TARGET_URL}` |
| `telegraf.influxDb.batch-enabled` | Enable InfluxDB batch writes | `true` |
| `telegraf.influxDb.batch-actions` | Batch action count threshold | `5000` |
| `telegraf.influxDb.buffer-limit` | Write buffer limit | `500000` |
| `telegraf.influxDb.flush-duration` | Flush interval in milliseconds | `500` |

### `jtier-metrics.*` — SMA writer configuration (active when `test-target=sma`)

| Property | Purpose | Example Value |
|----------|---------|---------------|
| `jtier-metrics.metricsWriter.bufferSize` | SMA buffer overflow pool size | `1500` |
| `jtier-metrics.metricsWriter.watermark` | Buffer fill level that triggers flush | `1000` |
| `jtier-metrics.metricsWriter.poolSize` | Number of overflow pool buffers | `3` |
| `jtier-metrics.metricsWriter.emitInternalTelemetry` | Emit jtier internal telemetry | `false` |
| `jtier-metrics.influxJavaHttpConfig.maxRequestPerHost` | Max concurrent HTTP requests per host | `20` |
| `jtier-metrics.influxJavaHttpConfig.maxIdleConnections` | Max idle HTTP connections in pool | `20` |
| `jtier-metrics.influxJavaHttpConfig.maxRequests` | Max total concurrent HTTP requests | `64` |
| `jtier-metrics.influxJavaHttpConfig.connectionKeepAliveTime` | Connection keep-alive in minutes | `5` |

### `sma.*` — SMA metric generation shape

| Property | Purpose | Default |
|----------|---------|---------|
| `sma.endpoints` | Number of simulated service endpoints | `5` |
| `sma.integrations` | Number of simulated integrations | `5` |
| `sma.integration-endpoints` | Number of endpoints per integration | `10` |

### `metrics.*` — Metric cardinality and naming

| Property | Purpose | Example Value |
|----------|---------|---------------|
| `metrics.shared-count` | Count of shared metric names (`metric.m.*`) | `150` |
| `metrics.cluster-count` | Count of cluster metric names (`metric.cm.*`) | `100` |
| `metrics.clusters-per-partition` | Clusters assigned to each partition | `5` |
| `metrics.mode` | Serialization format: `InfluxLineProtocol` or `JSON` | `InfluxLineProtocol` |
| `metrics.sources-per-cluster.low` | Min sources per cluster (normal distribution) | `2` |
| `metrics.sources-per-cluster.high` | Max sources per cluster | `30` |
| `metrics.sources-per-cluster.mean` | Mean sources per cluster | `5` |
| `metrics.sources-per-cluster.dev` | Std deviation for sources per cluster | `6` |

### `aggregation.*` — Post-load verification

| Property | Purpose |
|----------|---------|
| `aggregation.gatewayUrl` | URL of the metrics gateway for gateway integration verification |
| `aggregation.telegrafUrl` | URL of Telegraf for integration verification writes |
| `aggregation.serviceName` | Service name tag used in verification metric writes (default: `aggVerify`) |
| `aggregation.metricName` | Metric name used in verification metric writes (default: `verifyMetric`) |
| `aggregation.wavefrontUrl` | Wavefront base URL for query API read-back |
| `aggregation.wavefrontKey` | Wavefront API key (Bearer token) |
| `aggregation.dataValues` | List of numeric values to write and verify |
| `aggregation.dataExpectations` | Map of aggregate name → expected value |
| `aggregation.dataValuesLate` | Late-arriving data values for late-data verification |
| `aggregation.dataExpectationsLate` | Expected aggregates for late data |

### `test.strategies.*` — Kafka routing overrides

| Property | Purpose | Default |
|----------|---------|---------|
| `test.strategies.topic-keys` | Comma-separated tag names used to compose the Kafka message key | `bucket_key` |
| `test.strategies.partition-count` | Limit to a subset of Kafka partitions | All partitions |
| `test.strategies.partition-selector` | Partition selection scheme: `RANDOM` or `SEQUENTIAL` | `SEQUENTIAL` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `aggregation.wavefrontKey` | Wavefront API key (Bearer token) for querying aggregated metrics | env / profile YAML |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The service uses Spring Boot profile-based configuration exclusively. Each test scenario has its own bundled YAML file. The `TARGET_URL` environment variable is the only runtime override required for `telegraf` and `sma` profiles. There are no Consul, Vault, or Helm-managed overrides evidenced in this repository.
