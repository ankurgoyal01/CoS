---
service: "merchant-lifecycle-service"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [kafka, mbus]
---

# Events

## Overview

Merchant Lifecycle Service participates in two-way asynchronous messaging via Kafka/MBus. The `continuumMlsSentinelService` container is the primary async participant: it consumes deal catalog and inventory update events to maintain local index state, and publishes confirmation events downstream. The `continuumMlsRinService` container is primarily synchronous but may trigger index updates as a side effect of certain command flows.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| MBus/Kafka (MLS topic) | `DealSnapshotUpdated` | Deal catalog snapshot processed and persisted to `mlsDealIndexPostgres` | deal UUID, snapshot version, update timestamp |
| MBus/Kafka (inventory topic) | `InventoryProductIndexed` | Inventory product payload received and written to `unitIndexPostgres` | product UUID, unit state, inventory source ID |

### DealSnapshotUpdated Detail

- **Topic**: MBus/Kafka MLS command/event topic
- **Trigger**: `sentinelProcessingFlows` completes a deal snapshot upsert into `mlsDealIndexPostgres`
- **Payload**: deal UUID, snapshot version, update timestamp, deal state summary
- **Consumers**: Known downstream analytics and Merchant Advisor consumers; full consumer list tracked in central architecture model
- **Guarantees**: at-least-once

### InventoryProductIndexed Detail

- **Topic**: MBus/Kafka inventory topic
- **Trigger**: `sentinelProcessingFlows` completes an inventory product index write to `unitIndexPostgres`
- **Payload**: product UUID, unit state, inventory source ID, indexed timestamp
- **Consumers**: Known downstream inventory consumers; full consumer list tracked in central architecture model
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| MBus/Kafka (deal catalog topic) | Deal catalog events | `sentinelMessageIngestion` -> `sentinelProcessingFlows` | Upserts deal snapshot records in `mlsDealIndexPostgres`; writes history events to `historyServicePostgres` |
| MBus/Kafka (inventory topic) | Inventory update events | `sentinelMessageIngestion` -> `sentinelProcessingFlows` | Writes inventory unit state to `unitIndexPostgres`; triggers FIS/VIS fetch for current inventory details |

### Deal Catalog Events Detail

- **Topic**: MBus/Kafka deal catalog topic (published by `continuumDealCatalogService`)
- **Handler**: `sentinelMessageIngestion` routes to `sentinelProcessingFlows` deal index and DLQ flow handlers
- **Idempotency**: Upsert semantics on `mlsDealIndexPostgres` provide effective idempotency
- **Error handling**: DLQ flow handler in `sentinelProcessingFlows` manages failed message processing
- **Processing order**: unordered (event-driven upsert)

### Inventory Update Events Detail

- **Topic**: MBus/Kafka inventory topic
- **Handler**: `sentinelMessageIngestion` routes to `sentinelProcessingFlows` unit flow handler
- **Idempotency**: Upsert semantics on `unitIndexPostgres` provide effective idempotency
- **Error handling**: DLQ flow handler in `sentinelProcessingFlows` manages failed message processing
- **Processing order**: unordered (event-driven upsert)

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| MBus/Kafka DLQ (MLS) | MLS command/event and inventory topics | Configured in JTier MessageBus | Operational procedures to be defined by service owner |

> DLQ configuration details are managed within the JTier MessageBus bundle configuration. Exact topic names and retention periods to be confirmed by service owner.
