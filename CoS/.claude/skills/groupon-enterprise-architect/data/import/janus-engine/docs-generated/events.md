---
service: "janus-engine"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [kafka, mbus]
---

# Events

## Overview

Janus Engine is entirely event-driven. It consumes raw domain events published to MBus by upstream Continuum services and publishes normalized canonical events to a set of tiered Kafka sink topics. In DLQ mode it also reprocesses failed events from dead-letter queues through the same pipeline. The `kafkaIngestionAdapter` and `replayIngestionAdapter` components additionally consume directly from Kafka topics in their respective modes.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `janus-cloud-tier1` | Canonical Janus event (tier 1) | Successful curation of a high-priority source event | source type, canonical schema version, entity ID, timestamp |
| `janus-cloud-tier2` | Canonical Janus event (tier 2) | Successful curation of a tier-2 priority source event | source type, canonical schema version, entity ID, timestamp |
| `janus-cloud-tier3` | Canonical Janus event (tier 3) | Successful curation of a tier-3 priority source event | source type, canonical schema version, entity ID, timestamp |
| `janus-cloud-impression` | Canonical impression event | Curation of an impression-type source event | impression metadata, entity ID, timestamp |
| `janus-cloud-email` | Canonical email event | Curation of an email-type source event | email metadata, entity ID, timestamp |
| `janus-cloud-raw` | Raw bridge event | MBUS_RAW or raw replay mode pass-through | raw source payload |

### Canonical Janus Event Detail

- **Topics**: `janus-cloud-tier1`, `janus-cloud-tier2`, `janus-cloud-tier3`, `janus-cloud-impression`, `janus-cloud-email`
- **Trigger**: Completion of curation by `curationProcessor` for each source event received from MBus or Kafka
- **Payload**: Canonical Janus event envelope as defined by mapper definitions in the Janus metadata service; routing to the appropriate sink topic is determined by curation rules
- **Consumers**: Downstream analytics, marketing, and data pipeline services consuming canonical Janus topics (tracked in the central architecture model)
- **Guarantees**: at-least-once (Kafka producer with standard acknowledgement; DLQ mode handles redelivery)

### Raw Bridge Event Detail

- **Topic**: `janus-cloud-raw`
- **Trigger**: `MBUS_RAW` mode pass-through or raw replay mode
- **Payload**: Unmodified source event payload bridged from MBus to Kafka
- **Consumers**: Downstream consumers requiring unmodified raw events (tracked in the central architecture model)
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| MBus (Orders topics) | OrderSnapshots, OrderProcessingActivities | `mbusIngestionAdapter` | Curated event published to `janus-cloud-tier*` |
| MBus (Users topics) | User account and identity lifecycle events | `mbusIngestionAdapter` | Curated event published to `janus-cloud-tier*` |
| MBus (Deal Catalog topics) | Deal snapshot events | `mbusIngestionAdapter` | Curated event published to `janus-cloud-tier*` |
| MBus (Inventory topics) | Inventory product/unit snapshot events | `mbusIngestionAdapter` | Curated event published to `janus-cloud-tier*` |
| MBus (Regulatory topics) | Regulatory consent log events | `mbusIngestionAdapter` | Curated event published to `janus-cloud-tier*` |
| MBus (Pricing topics) | Dynamic pricing events | `mbusIngestionAdapter` | Curated event published to `janus-cloud-tier*` |
| Kafka (source topics) | Raw domain events | `kafkaIngestionAdapter` | Curated event published to `janus-cloud-tier*` via Kafka Streams topology |
| Kafka (raw/curated replay topics) | Janus raw/curated events | `replayIngestionAdapter` | Events replayed through curation and republished to sink topics |
| MBus DLQ topics | Failed curation events | `dlqProcessor` | Events reprocessed through `curationProcessor` and republished |

### MBus Source Event Detail

- **Handler**: `mbusIngestionAdapter` — uses RxJava and MBus client 1.5.2 to subscribe to configured topic/queue names
- **Idempotency**: No evidence of explicit idempotency guarantees; at-least-once delivery from MBus
- **Error handling**: Failed events are routed to dead-letter queues for reprocessing via DLQ mode
- **Processing order**: Ordered per topic/partition

### Kafka Source Event Detail

- **Handler**: `kafkaIngestionAdapter` — uses Kafka Streams 2.7.0 topology
- **Idempotency**: Kafka Streams provides at-least-once semantics by default
- **Error handling**: Kafka Streams error handling; unprocessable events may be sent to DLQ topics
- **Processing order**: Ordered per Kafka partition

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| MBus DLQ topics | MBus source topics (Orders, Users, Deal Catalog, Inventory, Regulatory, Pricing) | Per MBus configuration | > No evidence found — alert configuration managed externally |

> DLQ mode (`DLQ` engine mode) is a first-class runtime mode of Janus Engine. When deployed in DLQ mode, the `dlqProcessor` component consumes failed events from the dead-letter queues and routes them through the same `curationProcessor` pipeline for recovery. See [DLQ Replay Flow](flows/dlq-replay.md).
