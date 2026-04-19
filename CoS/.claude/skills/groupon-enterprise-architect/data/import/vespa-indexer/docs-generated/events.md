---
service: "vespa-indexer"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Vespa Indexer is a pure consumer of asynchronous events. It subscribes to a single Groupon MessageBus (STOMP) topic for real-time deal change notifications and does not publish any events. The MessageBus integration uses `stomp.py` 8.2.0 with ACK/NACK support for reliable message processing. Region filtering via `allowed_distribution_regions` (default: `["US"]`) ensures only relevant deals are indexed.

## Published Events

> No evidence found in codebase. This service does not publish any async events.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.topic.mars.mds.genericchange` | Deal change (create / update) | `consumeDealUpdatesUseCase` via `dealUpdateAdapter` / `mbusDealUpdateClient` | Upserts or partially updates Vespa documents for affected deal options |

### Deal Change Event Detail

- **Topic**: `jms.topic.mars.mds.genericchange`
- **Broker**: `mbus.production.service` (production); staging is disabled per `.cursor/mbus/mbus.mdc`
- **Protocol**: STOMP (`stomp.py` 8.2.0); port configured via `MBUS_PORT` (default: `61613`)
- **Handler**: `DealUpdateAdapter` subscribes to the topic, yields `DealOption` or `DealOptionUpdate` objects; `ConsumeDealUpdatesUseCase` decides whether to call `SearchIndex.index_option()` (full create) or `update_option()` (partial update) based on message type
- **Region filtering**: Messages with `distribution_region_codes` not in `allowed_distribution_regions` are skipped before indexing
- **Payload key fields** (from `.cursor/mbus/examples/create_deal.json`):
  - `dealUuid` — deal UUID
  - `versionId` — message version
  - `changes.options[]` — array of option objects with `id`, `price`, `title`, `active`, `redemption_locations`, `discount_percent`, `is_bookable`, `redemption_method`
  - `changes.distribution_region_codes` — list of region codes for filtering
  - `source` — originating service (e.g. `deal-service-api-jtier`)
- **BigQuery enrichment**: On CREATE messages, `bigQueryDealOptionEnricher` fetches ML features and merges them into the document before writing to Vespa
- **Idempotency**: Vespa upserts are idempotent by document ID; re-processing the same message overwrites the existing document
- **Error handling**: Messages that fail processing are NACKed; MessageBus handles redelivery according to broker policy
- **Processing order**: Unordered (STOMP subscription, no per-key ordering guarantee)

## Dead Letter Queues

> No evidence found in codebase of a configured DLQ. NACK causes MessageBus broker-side redelivery.
