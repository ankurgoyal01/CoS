---
service: "push-infrastructure"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 8
---

# Flows

Process and flow documentation for Push Infrastructure (Rocketman v2).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Message Enqueue](message-enqueue.md) | synchronous | API call to `/enqueue_user_message` or `/send/v1/sends` | Receives an inbound message request, validates, and places it onto a Redis delivery queue |
| [Event-Triggered Email](event-triggered-email.md) | event-driven | Kafka topic consumption (rm_daf, rm_preflight, rm_rapi, rm_mds, rm_feynman) | Consumes Kafka events from upstream services and converts them into queued email delivery jobs |
| [Campaign Assembly and Scheduling](campaign-assembly-scheduling.md) | scheduled | API call to `/schedule` or Quartz trigger | Assembles campaign message batches and schedules them for time-delayed or cron-based delivery |
| [Message Processing and Delivery](message-processing-delivery.md) | asynchronous | Redis queue worker cycle | Dequeues messages from Redis, renders templates, and dispatches to SMTP/SMS Gateway/FCM/APNs |
| [Error Retry](error-retry.md) | synchronous | API call to `/errors/retry` | Retrieves failed delivery records from PostgreSQL and re-enqueues them for reprocessing |
| [Template Rendering](template-rendering.md) | synchronous | API call to `/render_template` or internal render request | Fetches template from Redis cache, merges with data context using FreeMarker, returns rendered content |
| [Campaign Stats Aggregation](campaign-stats-aggregation.md) | synchronous | API call to `/campaign/stats` | Queries PostgreSQL delivery records and aggregates per-campaign delivery statistics |
| [Cache Invalidation](cache-invalidation.md) | synchronous | API call to `/cache/invalidate` | Removes stale template entries from Redis cache to force re-fetch on next render |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The following flows span multiple services and reference the central architecture model:

- **Event-Triggered Email** involves upstream Kafka producers (rm_daf, rm_preflight, rm_coupon, rm_user_queue_default, rm_rapi, rm_mds, rm_feynman topics) published by other Continuum platform services — see `continuumSystem` container diagram
- **Message Processing and Delivery** terminates at external delivery providers (SMTP, FCM/APNs, SMS Gateway) and publishes status back to `externalRabbitMqBroker_4a6b` (`status-exchange`)
- **Campaign Assembly and Scheduling** is triggered by upstream campaign orchestration services that call the `/schedule` API on `continuumPushInfrastructureService`

> No dynamic views have been defined in the architecture DSL yet. See the flow files for full sequence diagrams.
