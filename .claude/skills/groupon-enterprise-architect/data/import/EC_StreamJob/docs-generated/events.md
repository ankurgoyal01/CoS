---
service: "EC_StreamJob"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["kafka"]
---

# Events

## Overview

EC_StreamJob is a pure Kafka consumer. It reads from one of two Janus tier-2 topics (depending on geographic colo) using the Spark Streaming direct Kafka API with a 20-second micro-batch interval. It does not publish any events to Kafka. All output is delivered via HTTP POST to the TDM API.

## Published Events

> Not applicable. This service does not publish any events to a message bus.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `janus-tier2` | Janus behavioral events (Avro) | `RealTimeJob` — NA colo | HTTP POST to TDM `/v1/updateUserData` for qualifying events |
| `janus-tier2_snc1` | Janus behavioral events (Avro) | `RealTimeJob` — EMEA colo | HTTP POST to TDM `/v1/updateUserData` for qualifying events |

### Janus Behavioral Events Detail

- **Topic (NA)**: `janus-tier2`
- **Topic (EMEA)**: `janus-tier2_snc1`
- **Broker (NA)**: `kafka.snc1:9092`
- **Broker (EMEA)**: `kafka.dub1:9092`
- **Consumer group (NA)**: `EC_StreamJobKafKaNAGroup`
- **Consumer group (EMEA)**: `EC_StreamJobKafKaEMEAGroup`
- **Client ID (NA)**: `EC_StreamJobKafKaNA`
- **Client ID (EMEA)**: `EC_StreamJobKafKaEMEA`
- **Encoding**: Avro (decoded via `AvroUtil.transform()` using Janus metadata API)
- **Handler**: `RealTimeJob.startJob()` — `foreachRDD` / `foreachPartition` loop
- **Filtered event types retained**: `dealview`, `dealpurchase`
- **Required fields for an event to pass filter**: `event`, `country`, `consumerId`, `bcookie`, `dealUUID`, `eventTime`, `rawEvent`, `platform` (all must be non-null)
- **Country filter (NA)**: `US` only
- **Country filter (EMEA)**: `UK`, `IT`, `FR`, `DE`, `ES`, `NL`, `PL`, `AE`, `BE`, `IE`, `NZ`, `AU`, `JP`
- **Idempotency**: Within-partition deduplication using a composite key (`event` + `country` + `bcookie` + `dealUUID` + `consumerId` + `platform` + `brand`). No cross-partition or cross-batch deduplication.
- **Error handling**: Batch timeout — if all TDM HTTP futures do not complete within 19 seconds, the batch is abandoned and the error is printed to stdout. Kafka offset advances regardless (no retry or DLQ).
- **Processing order**: Unordered (parallel per partition, 10 threads per partition)
- **Batch interval**: 20 seconds (`BATCH_INTERVAL = 20`)
- **Max batch delay**: 19 seconds (`MAX_DELAY = 19`)
- **Max fetch size**: 10,000,000 bytes per message (`fetch.message.max.bytes`)
- **Backpressure**: Enabled (`spark.streaming.backpressure.enabled = true`)

## Dead Letter Queues

> No evidence found in codebase. No DLQ or retry mechanism is implemented for failed Kafka messages or failed TDM HTTP calls.
