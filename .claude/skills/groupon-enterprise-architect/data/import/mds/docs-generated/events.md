---
service: "mds"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [mbus, redis-queue]
---

# Events

## Overview

MDS operates as both a producer and consumer of asynchronous events. It consumes deal lifecycle events from the shared message bus (JMS/STOMP) and Deal Catalog Service event streams, processes them through its enrichment pipeline, and publishes enriched deal-change notifications and inventory status updates back to the message bus. Internally, Redis-backed queues are used for deal processing orchestration, distributed locking, retry scheduling, and notification publishing between the worker and API layers.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Message Bus (MBus) | `deal-change-notification` | Deal enrichment pipeline completes processing | deal_id, change_type, enrichment_summary, timestamp |
| Message Bus (MBus) | `inventory-option-status-update` | Inventory status changes detected during enrichment | deal_id, option_id, inventory_status, inventory_service_source |
| Marketing Platform (HTTP + Events) | `deal-data-update` | Enriched deal data published to marketing systems | deal_id, enriched_deal_payload, distribution_channels |
| Redis Queue (internal) | `deal-processing-notification` | Deal Processing Worker completes a processing cycle | deal_id, processing_status, retry_count |

### `deal-change-notification` Detail

- **Topic**: Shared message bus (MBus)
- **Trigger**: The Deal Enrichment Pipeline completes processing a deal update, producing computed deltas. The Notification Publisher emits the notification to the bus.
- **Payload**: deal_id, change_type (created, updated, enriched), enrichment_summary (fields changed), timestamp
- **Consumers**: Marketing Platform, downstream deal consumers, partner feed systems
- **Guarantees**: at-least-once (MBus/JMS acknowledgment semantics)

### `inventory-option-status-update` Detail

- **Topic**: Shared message bus (MBus)
- **Trigger**: The Deal Enrichment Pipeline detects inventory status changes across one or more inventory services. The Inventory Update Publisher emits option-level updates to the bus via the NBus Producer.
- **Payload**: deal_id, option_id, inventory_status (available, sold_out, limited), inventory_service_source (voucher, goods, travel, third_party, glive)
- **Consumers**: Marketing Platform, availability display systems
- **Guarantees**: at-least-once (NBus producer acknowledgment)

### `deal-data-update` Detail

- **Topic**: Marketing Platform endpoint (HTTP + Events)
- **Trigger**: Enriched deal data is ready for distribution to marketing and advertising systems
- **Payload**: Full enriched deal representation including taxonomy, location, pricing, inventory status, and performance data
- **Consumers**: `continuumMarketingPlatform`
- **Guarantees**: at-least-once (HTTP with retry)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Message Bus (MBus) | `deal-lifecycle-event` | Deal Processing Worker (`mdsDealProcessingWorker`) | Enqueues deal for enrichment pipeline processing |
| Deal Catalog Service (HTTP + Events) | `catalog-update-event` | External Service Adapters (`externalAdapters`) | Fetches updated catalog data; triggers re-enrichment |
| Redis Queue (internal) | `deal-processing-queue` | Deal Processing Worker (`mdsDealProcessingWorker`) | Processes queued deal identifiers through enrichment pipeline |

### `deal-lifecycle-event` Detail

- **Topic**: Shared message bus (MBus) via JMS/STOMP
- **Handler**: Deal Processing Worker consumes deal identifiers from the bus, manages distributed locks via Redis, and orchestrates the fetch/update flow through the enrichment pipeline.
- **Idempotency**: Yes — distributed locking via Redis ensures a deal is processed by only one worker instance at a time; re-processing a deal produces the same enrichment result.
- **Error handling**: Failed enrichment attempts are retried via Redis-based retry scheduling with exponential backoff. After max retries, the deal is logged and flagged for manual review.
- **Processing order**: Unordered (deals are processed independently; ordering within a single deal is ensured by distributed locks)

### `catalog-update-event` Detail

- **Topic**: Deal Catalog Service event stream (HTTP + Events)
- **Handler**: External Service Adapters consume catalog update notifications and trigger re-enrichment for affected deals.
- **Idempotency**: Yes — re-enrichment is deterministic based on current upstream state.
- **Error handling**: Retried via standard HTTP retry logic; failures logged to the logging stack.
- **Processing order**: Unordered

## Dead Letter Queues

| DLQ | Source Topic | Retention | Alert |
|-----|-------------|-----------|-------|
| Redis failed-processing queue | deal-processing-queue | Until manual review | Alert on queue depth > threshold |
| MBus DLQ (platform-managed) | deal-lifecycle-event | Per MBus platform retention policy | Platform-level alerting |

> Failed deal processing jobs that exceed retry limits are placed in a Redis-backed failed queue for manual inspection. Message bus dead letter handling follows the Continuum platform MBus conventions.
