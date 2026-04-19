---
service: "EC_StreamJob"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 4
---

# Integrations

## Overview

EC_StreamJob has four internal Groupon platform dependencies and no external (third-party) dependencies beyond the Spark/YARN execution cluster. It reads from Kafka, calls the Janus metadata API for Avro schema resolution, and posts enriched events to the TDM API. All dependencies are downstream (this service calls them); no service calls EC_StreamJob.

## External Dependencies

> No evidence found in codebase. No third-party external service integrations detected.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Kafka (janus-tier2 / janus-tier2_snc1) | Kafka direct (0.8) | Source of real-time Janus behavioral events | `kafkaTopicJanusTier2` |
| Janus metadata API | HTTP | Resolves Avro schemas for event decoding via `AvroUtil.transform()` | `janusApi` |
| Targeted Deal Message API (TDM) | HTTP/JSON | Receives enriched user deal-interaction events via `POST /v1/updateUserData` | `tdmApi` |
| Spark / YARN cluster | Spark/YARN | Execution environment; manages job scheduling, executors, and resource allocation | `sparkStreamingCluster` |

### Kafka Detail

- **Protocol**: Kafka direct consumer (Kafka 0.8 API via `spark-streaming-kafka-0-8`)
- **Broker (NA)**: `kafka.snc1:9092`
- **Broker (EMEA)**: `kafka.dub1:9092`
- **Topics**: `janus-tier2` (NA), `janus-tier2_snc1` (EMEA)
- **Auth**: No auth evidence in codebase
- **Purpose**: Provides the stream of Avro-encoded Janus behavioral events to process
- **Failure mode**: Spark Streaming will stall and eventually time out the batch; backpressure is enabled to reduce consumption rate under load
- **Circuit breaker**: No evidence found

### Janus Metadata API Detail

- **Protocol**: HTTP
- **Base URL (EMEA prod)**: `http://janus-metadata-management-app.dub1`
- **Base URL (all others)**: `JanusBaseURL.PROD.getUrl` (resolved from `janus-mapper` library constant)
- **Auth**: No auth evidence in codebase
- **Purpose**: Provides Avro schema metadata used by `AvroUtil.transform()` to decode raw Kafka message bytes into JSON
- **Failure mode**: Avro decoding would fail, causing events to be skipped or the batch to fail
- **Circuit breaker**: No evidence found

### Targeted Deal Message API (TDM) Detail

- **Protocol**: HTTP/JSON POST
- **Base URL (NA staging)**: `http://targeted-deal-message-app1-staging.snc1:8080/v1/updateUserData`
- **Base URL (EMEA staging)**: `http://targeted-deal-message-app2-emea-staging.snc1:8080/v1/updateUserData`
- **Base URL (NA prod)**: `http://targeted-deal-message-app-vip.snc1/v1/updateUserData`
- **Base URL (EMEA prod)**: `http://targeted-deal-message-app-vip.dub1/v1/updateUserData`
- **Auth**: No auth evidence in codebase
- **Request timeout**: 2000 ms (`API_TIMEOUT = 2000`)
- **Concurrency**: 10 threads per Spark partition (`THREAD_POOL_SIZE = 10`)
- **Content-Type**: `application/json`
- **Purpose**: Receives user deal-view and deal-purchase events to update personalization state
- **Failure mode**: If all futures do not complete within 19 seconds the batch is abandoned; individual failed futures are not retried
- **Circuit breaker**: No evidence found

### Spark / YARN Cluster Detail

- **Protocol**: Spark submit over YARN
- **Cluster (NA)**: `gdoop-resourcemanager2.snc1` — `gdoop-job-submitter5.snc1`
- **Cluster (EMEA)**: `gdoop-resourcemanager2.dub1` — `gdoop-job-submitter1.dub1`
- **Submit command**: `spark-submit --master yarn --executor-memory 1g --queue public --driver-memory 1g --executor-cores 4 --class com.groupon.sparkStreamJob.RealTimeJob EC_StreamJob.jar {colo} {env}`
- **Purpose**: Provides distributed execution runtime for the streaming job

## Consumed By

> No evidence found in codebase. Upstream consumers are not applicable — this is a streaming job, not a service. No inbound callers exist.

## Dependency Health

- TDM HTTP call has a 2-second timeout per request (`API_TIMEOUT = 2000 ms`).
- The entire partition batch is bounded to 19 seconds (`MAX_DELAY = 19 s`) via `Await.result` with a timeout.
- Backpressure is enabled on the Spark Streaming context (`spark.streaming.backpressure.enabled = true`) to throttle Kafka consumption when processing falls behind.
- No circuit breakers, retries, or dead-letter strategies are implemented for any dependency.
