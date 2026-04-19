---
service: "merchant-lifecycle-service"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Merchant Lifecycle Service (MLS RIN).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Unit Search Aggregation](unit-search-aggregation.md) | synchronous | API call — `POST /units/v1/search` | Aggregates unit search results from local index and multiple upstream services into a single response |
| [Deal Lifecycle Event Processing](deal-lifecycle-event-processing.md) | event-driven | Kafka deal catalog event from `continuumDealCatalogService` | Processes incoming deal snapshot and update events to maintain the MLS deal index |
| [Merchant Insights Aggregation](merchant-insights-aggregation.md) | synchronous | API call — `GET /insights/merchant/{uuid}/analytics` or `/cxhealth` | Aggregates merchant analytics and CX health data from local stores and upstream services |
| [Deal Index Snapshot Maintenance](deal-index-snapshot-maintenance.md) | event-driven | Kafka deal catalog snapshot event | Keeps `mlsDealIndexPostgres` in sync with the authoritative deal catalog by upserting deal snapshots |
| [Unit Inventory State Sync](unit-inventory-state-sync.md) | event-driven | Kafka inventory update event | Processes inventory update events from MBus and syncs unit state into `unitIndexPostgres` |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- **Deal Lifecycle Event Processing** and **Deal Index Snapshot Maintenance** both originate from `continuumDealCatalogService` publishing to `messageBus`. The central architecture dynamic view is `dynamic-mls-sentinel-inventory-update`.
- **Unit Inventory State Sync** is driven by inventory update events routed through `messageBus` from FIS/VIS upstream producers.
- All three event-driven flows are handled by `continuumMlsSentinelService` components (`sentinelMessageIngestion`, `sentinelProcessingFlows`, `sentinelPersistence`).
