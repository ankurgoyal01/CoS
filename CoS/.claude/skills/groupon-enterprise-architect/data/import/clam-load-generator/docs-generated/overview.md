---
service: "clam-load-generator"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Metrics / Observability / Load Testing"
platform: "Continuum Metrics"
team: "Metrics"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Spring Boot"
  framework_version: "2.1.11.RELEASE"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# CLAM Load Generator Overview

## Purpose

The CLAM Load Generator is a Spring Boot service that generates synthetic, high-volume metrics payloads and dispatches them to one of three configurable target backends: Apache Kafka, Telegraf/InfluxDB, or SMA (Service Metrics API via jtier). Its primary role is to load-test the CLAM (Continuum Logging and Metrics) pipeline and Telegraf aggregation infrastructure, producing realistic traffic patterns to validate throughput, correctness, and latency under load. After load generation completes, optional verification phases query Wavefront to assert that aggregated metrics match expected values.

## Scope

### In scope

- Generating synthetic metric payloads in Kafka line-protocol (JSON or InfluxDB line-protocol format) and publishing them to a configured Kafka topic across all or selected partitions.
- Generating InfluxDB line-protocol metric points and writing them directly to a Telegraf HTTP listener endpoint.
- Building SMA measurement batches and submitting them through the jtier `MeasurementWriter` / `BufferingInfluxWriter` stack.
- Rate-limiting and concurrency control for load generation (configurable threads, `ratePerSecond`, `maxOperations`, and `timeout`).
- Post-load verification against Telegraf and the metrics gateway by querying Wavefront for aggregated metric values and comparing against expected results.
- Optional WireMock HTTP server for mocking Telegraf endpoints during local development and testing.

### Out of scope

- Receiving or consuming metrics from any source — this service is a producer/writer only.
- Persistent storage of generated metrics — data is written directly to target backends.
- Aggregation or transformation of metrics — that is handled downstream by CLAM/Telegraf.
- Serving a public HTTP API — the service has no inbound REST interface.

## Domain Context

- **Business domain**: Metrics / Observability / Load Testing
- **Platform**: Continuum Metrics
- **Upstream consumers**: No upstream callers — this service is triggered at startup and runs to completion.
- **Downstream dependencies**: Apache Kafka (`histograms_v2` topic), Telegraf HTTP listener (`telegraf.url`), Wavefront Query API (`aggregation.wavefrontUrl`), and optionally the metrics gateway (`aggregation.gatewayUrl`).

## Stakeholders

| Role | Description |
|------|-------------|
| Metrics Platform Engineers | Operate and extend the load generator to validate CLAM/Telegraf pipeline changes |
| SRE / Performance Engineers | Run load tests before and after infrastructure changes to verify throughput |
| Slack channel | `#bot---metrics` (CI/CD notifications) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` `<java.version>11</java.version>` |
| Framework | Spring Boot | 2.1.11.RELEASE | `pom.xml` `<parent>` |
| Build tool | Maven | 3.6.3 | `Dockerfile` `FROM maven:3.6.3-jdk-11` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spring-kafka` | (Spring Boot BOM) | message-client | Kafka producer factory and `KafkaTemplate` for partition-level metric publishing |
| `influxdb-java` | 2.15 | db-client | InfluxDB/Telegraf HTTP write client and `BatchOptions` configuration |
| `t-digest` | 3.2 | metrics | AVL-tree digest (histogram compression) for gateway integration verification payloads |
| `guava` | 28.2-jre | utility | `RateLimiter` for per-second throughput control during load generation |
| `okhttp` | 2.7.5 | http-framework | HTTP client used by the generated Wavefront Swagger client |
| `okhttp3` (via jtier) | — | http-framework | OkHttp3 `ConnectionPool` and `Dispatcher` configuration for SMA writes |
| `metrics-sma-influxdb` | 0.10.2 | metrics | jtier `BufferingInfluxWriter` and `HandoverAsyncExecutor` for SMA measurement submission |
| `metrics-sma` | 0.10.2 | metrics | jtier `MeasurementWriter`, `MetricsSubmitter`, `ImmutableMeasurement` SMA API |
| `wiremock-jre8` | 2.26.3 | testing | Optional local WireMock server mocking Telegraf endpoints on port 2345 |
| `jackson-databind` | (Spring Boot BOM) | serialization | JSON serialization of `Line` payloads for Kafka messages |
| `commons-lang3` | (Spring Boot BOM) | utility | `StringUtils.isNotEmpty` for conditional verifier activation |
| `gson` / `gson-fire` | BOM / 1.8.3 | serialization | Wavefront Swagger client deserialization of `RawTimeseries` and `QueryResult` |
