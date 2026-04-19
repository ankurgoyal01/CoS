---
service: "deal-service"
title: Flows
generated: "2026-03-02"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Deal Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Deal Processing Cycle](deal-processing-cycle.md) | batch / scheduled | Continuous timer (every 5s via `feature_flags.processDeals.intervalInSec`) | Master forks worker; worker polls Redis queue; fills queue from MongoDB when low; processes batches of up to 400 deals |
| [Deal State Update and Inventory Publish](deal-state-update-and-inventory-publish.md) | asynchronous | Single deal dequeued from `processing_cloud` | Fetches catalog data, calculates margins/forex, enriches metadata, persists to Postgres and MongoDB, publishes inventory updates to message bus |
| [Redis Scheduler Retry](redis-scheduler-retry.md) | event-driven | Failed deal added to `nodejs_deal_scheduler` sorted set | Retry backoff: failed deals are scored by timestamp in a Redis sorted set; scheduler re-enqueues them into `processing_cloud` when due |
| [Deal Notification Publish](deal-notification-publish.md) | asynchronous | Deal active status changes or deal expires | Publishes JSON notification payload to `{event_notification}.message` Redis list for downstream notification consumers |
| [Dynamic Configuration Reload](dynamic-configuration-reload.md) | event-driven | Service startup + `configUpdate` event from keldor-config | keldor-config loads on startup; registers `configUpdate` listener; all handlers use shared `gConfig` object updated in place |
| [Worker Process Restart](worker-process-restart.md) | continuous | Worker process exits (crash or normal termination) | Master process detects worker exit, auto-forks a new worker without data loss (in-flight jobs remain in Redis) |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |
| Event-driven (internal) | 2 |
| Continuous (process management) | 1 |

## Cross-Service Flows

- The [Deal State Update and Inventory Publish](deal-state-update-and-inventory-publish.md) flow spans `continuumDealService`, `continuumDealManagementApi`, `continuumGoodsStoresApi`, `salesForce`, and `messageBus`. Refer to the central architecture model for the full cross-service dynamic view once defined.
- No dynamic views are currently defined in `architecture/views/dynamics.dsl` for this service.
