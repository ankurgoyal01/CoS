---
service: "mobile-logging-v2"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

Mobile Logging V2 is a Kafka producer only — it publishes normalised GRP telemetry events to the `mobile_tracking` topic. The service does not consume from any Kafka topic. All events are encoded using the Loggernaut serialisation format (`kafka-message-serde`) before being sent to the broker over a TLS-authenticated connection. The service maintains a primary Kafka producer (`kafkaProducer`) and a secondary EMEA producer (`kafkaEmeaProducer`) as configured.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `mobile_tracking` | GRP events (GRP5, GRP7, GRP8, GRP9, GRP14, GRP40, and generic GRP-prefixed types) | Successful decode of a mobile log upload via `POST /v2/mobile/logs` | `eventType`, `clientPlatform`, `clientVersion`, `clientDeviceID`, `clientBcookie`, `sessionId`, `time`, `clientLocale`, `brand`, event-specific fields |

### GRP Mobile Telemetry Events Detail

- **Topic**: `mobile_tracking`
- **Trigger**: A mobile client POSTs a valid MessagePack log file; for each valid GRP event row decoded from the payload, one Kafka message is published
- **Payload**: Denormalised JSON object merging client header fields and event-specific fields. Key fields include:
  - `eventType` — GRP type identifier (e.g., `GRP5`, `GRP7`, `GRP14`)
  - `clientPlatform` — `ANDCON` (Android) or iOS variant
  - `clientVersion` — app version string (e.g., `22.23.449759`)
  - `clientDeviceID` — device identifier
  - `clientBcookie` — browser cookie / device fingerprint
  - `sessionId` — client session UUID
  - `time` — epoch timestamp in milliseconds
  - `clientLocale` — locale string (used to derive `region`: `USCA` or `INTL`)
  - `grouponVersion` — `legacy` or `mbnxt`
  - `brand` — e.g., `groupon`
  - Event-specific fields (`_eventfield1`…`_eventfieldN`, or named fields for typed events)
- **Consumers**: Janus (data analytics pipeline); downstream data platform consumers
- **Guarantees**: At-least-once (Kafka producer `acks=1`, `retries=1`)

### Typed GRP Event Variants

The following event types receive specialised field mapping and additional per-event metrics:

| Event Type | Description | Special Handling |
|------------|-------------|-----------------|
| `GRP5` | Purchase confirmation (checkout) | Extracts `errorCode` → success/error result; extracts `paymentType`/`payment_type` from `_eventfield21` |
| `GRP7` | API call telemetry | Filtered out when URL equals `https://logging.groupon.com/v2/mobile/logs` (self-logging noise) |
| `GRP8` | Android image performance event | Filtered out when `clientPlatform=ANDCON` and `category=ImagePerfEvent` |
| `GRP9` | Generic event (typed schema) | Standard event schema mapping |
| `GRP14` | Screen view event | Standard event schema mapping |
| `GRP40` | Request/response debug event | `_eventfield6` and `_eventfield7` redacted to `[redacted]` to avoid PII exposure |
| `GRP36`, others | Generic GRP events | Mapped using default `MobileEventFields` schema |

## Consumed Events

> This service does not publish or consume async events from any inbound topic. It is a pure Kafka producer.

## Dead Letter Queues

> No evidence found of a configured dead-letter queue. Failed Kafka send attempts are logged as `KAFKA_SEND` log events and counted under the `error` metrics outcome; the service does not retry beyond the configured `retries=1` Kafka producer setting.
