---
service: "clam-load-generator"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 0
---

# Integrations

## Overview

The CLAM Load Generator has four external outbound integrations and no internal service-to-service dependencies. Its integration pattern is entirely write-forward (Kafka, Telegraf, SMA) with a single read-back integration (Wavefront) used only during post-load verification. All integrations are configured per-profile via Spring Boot YAML properties files.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Apache Kafka | Kafka producer (snappy, 128 KB batch) | Receive synthetic metric line-protocol messages for CLAM pipeline load testing | Yes (kafka mode) | `continuumMetricsClamLoadGenerator` |
| Telegraf HTTP listener | HTTP / InfluxDB line-protocol | Receive synthetic InfluxDB `Point` writes for throughput and aggregation testing | Yes (telegraf/sma modes) | `continuumMetricsClamLoadGenerator` |
| Wavefront Query API | REST / Bearer token (api_key) | Read back aggregated metric timeseries to verify post-load correctness | Yes (verification phases) | `continuumMetricsClamLoadGenerator` |
| Metrics Gateway | HTTP / InfluxDB line-protocol | Receive digest-encoded T-Digest payloads for gateway aggregation integration testing | No (optional verification) | `continuumMetricsClamLoadGenerator` |

### Apache Kafka Detail

- **Protocol**: Kafka producer (`spring-kafka`, `StringSerializer` for key and value)
- **Base URL / SDK**: `kafka.broker-address` — example: `kafka-08-broker-staging-vip.snc1:9092` (from `application-kafka-minimal.yml`)
- **Auth**: No authentication configured (internal broker)
- **Purpose**: Publish synthetic metric JSON payloads to the `histograms_v2` topic (configurable via `kafka.topic`) across all discovered or selected partitions, simulating production metric ingest load for CLAM pipeline validation
- **Failure mode**: `JsonProcessingException` results in `OperationResult.FAILURE` logged in the load summary; Kafka producer errors logged via standard producer error callbacks
- **Circuit breaker**: No — not applicable for a one-shot load testing tool

### Telegraf HTTP Listener Detail

- **Protocol**: HTTP POST / InfluxDB line-protocol via `influxdb-java` 2.15
- **Base URL / SDK**: `telegraf.url` — resolved from `TARGET_URL` environment variable at runtime (example: `http://telegraf-agent1-uat.snc1:8186/`)
- **Auth**: None (internal endpoint)
- **Purpose**: Write synthetic InfluxDB `Point` objects directly to a Telegraf HTTP listener to load-test Telegraf's ingest capacity and aggregation correctness
- **Failure mode**: Write errors are logged via `InfluxDB.BatchOptions.exceptionHandler`; connection is closed in `after()` lifecycle method
- **Circuit breaker**: No

### Wavefront Query API Detail

- **Protocol**: REST/HTTP GET via generated Swagger client (`io.swagger.client.api.QueryApi`)
- **Base URL / SDK**: `aggregation.wavefrontUrl` — configured per profile
- **Auth**: Bearer token (`aggregation.wavefrontKey` set as `api_key` in `ApiKeyAuth`)
- **Purpose**: Query `GET /api/v2/chart/raw` to read back aggregated metric timeseries after load generation, verifying that actual values match `aggregation.dataExpectations`
- **Failure mode**: `ApiException` is caught and stack-traced; verification polling retries up to 12 times (5-second intervals, 60-second initial delay)
- **Circuit breaker**: No — polling loop has a maximum of 12 × 5s = 60 seconds retry window per metric

### Metrics Gateway Detail

- **Protocol**: HTTP / InfluxDB line-protocol via `InfluxDBFactory.connect(aggregation.gatewayUrl)`
- **Base URL / SDK**: `aggregation.gatewayUrl` — configured per profile
- **Auth**: None
- **Purpose**: Write T-Digest centroid-encoded payloads (with `bucket_key`, `aggregates`, `compression`, `sum._utility`, `centroids` fields) to the gateway to verify end-to-end digest aggregation correctness
- **Failure mode**: Verifier is skipped entirely when `aggregation.gatewayUrl` is empty (checked via `StringUtils.isNotEmpty`)
- **Circuit breaker**: No

## Internal Dependencies

> No evidence found in codebase. The CLAM Load Generator has no internal service-to-service dependencies within the Groupon microservice ecosystem. All dependencies are external backends.

## Consumed By

> Upstream consumers are tracked in the central architecture model. This service is a utility tool invoked by engineers or CI jobs; it is not called by other services.

## Dependency Health

- **Kafka**: Connection health is validated implicitly at startup via `KafkaTemplate.partitionsFor()` during the `before()` phase. No explicit health check endpoint.
- **Telegraf**: Connection is established via `InfluxDBFactory.connect()` in `before()`. Batch error handler logs failures.
- **Wavefront**: Checked implicitly during verification polling; `isEnabled()` guards execution based on whether `aggregation.wavefrontUrl` is non-empty.
- **WireMock** (optional local mock): When `wiremock.enabled=true`, a WireMock server starts on port 2345 and serves stub responses from `src/main/resources` to replace Telegraf during local testing.
