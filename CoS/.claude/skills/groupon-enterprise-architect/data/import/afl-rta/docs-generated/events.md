---
service: "afl-rta"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka, mbus]
---

# Events

## Overview

AFL RTA is an event-driven service built entirely around asynchronous messaging. It consumes two event types from a single Kafka topic (`janus-tier2`) produced by the Janus data-engineering pipeline, and publishes attributed order records to an MBus/JMS queue for downstream partner channel processing. Kafka consumption is performed via a polling loop (`RtaPollingConsumer`); MBus publishing is performed by `MBusOrderRegistration` for enabled channels, with `LoggingOrderRegistration` as a fallback path.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `messageBus` (MBus/JMS) | Attributed Order | Successful order attribution for a partner channel | order ID, channel, affiliate ID, attribution tier, deal details, customer status |

### Attributed Order Detail

- **Topic**: `messageBus` (MBus/JMS queue; specific queue name managed by JTier messagebus configuration)
- **Trigger**: A `dealPurchase` event is consumed from Kafka, correlated with a click within the 7-day referral window, enriched with Orders API and MDS data, and determined to belong to a partner channel with MBus publishing enabled
- **Payload**: Attributed order data including order ID (legacy numeric or UUID format), marketing channel identifier, affiliate ID, deal taxonomy details, deal option details, and customer new/returning status
- **Consumers**: `afl-3pgw` (Commission Junction gateway) and other configured partner channel downstream consumers
- **Guarantees**: at-least-once (Kafka consumer commits offsets after processing; MBus publish failures fall back to `LoggingOrderRegistration`)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `janus-tier2` (Kafka) | `externalReferrer` | `ClickAttributionStrategy` via `EventProcessor` | Registers attributed click in `continuumAflRtaMySql` |
| `janus-tier2` (Kafka) | `dealPurchase` | `OrderAttributionStrategy` via `EventProcessor` | Looks up click history, publishes to MBus, persists attributed order to `continuumAflRtaMySql` |

### `externalReferrer` Event Detail

- **Topic**: `janus-tier2` (Kafka; managed by data-engineering Janus team)
- **Handler**: `RtaPollingConsumer` polls records, `EventProcessor` routes to `ClickAttributionStrategy`, which calls `ClicksService` to register the attributed click
- **Idempotency**: Click registration uses the bcookie as the correlation key; duplicate processing may result in duplicate click records but does not cause downstream MBus publishes
- **Error handling**: URL parsing failures (`java.net.URISyntaxException`) are logged and skipped; no DLQ configured at the Kafka consumer level — offsets are committed to continue processing
- **Processing order**: Ordered within Kafka partition

### `dealPurchase` Event Detail

- **Topic**: `janus-tier2` (Kafka; managed by data-engineering Janus team)
- **Handler**: `RtaPollingConsumer` polls records, `EventProcessor` routes to `OrderAttributionStrategy`, which reads click history by bcookie, resolves order IDs, enriches with Orders API and MDS, then delegates to `OrderRegistrationFactory` to select and invoke either `MBusOrderRegistration` or `LoggingOrderRegistration`
- **Idempotency**: Attributed orders are stored in MySQL with deduplication; re-processing the same order may result in duplicate MBus publishes if the first write succeeded but the offset was not committed
- **Error handling**: If `MBusOrderRegistration` fails, `LoggingOrderRegistration` logs the attributed order as a fallback; no external DLQ; Kafka consumer resumes from last committed offset on restart
- **Processing order**: Ordered within Kafka partition

## Dead Letter Queues

> No evidence found of a dedicated DLQ configuration in this repository. Failure handling relies on the `LoggingOrderRegistration` fallback and Kafka offset re-consumption on service restart.
