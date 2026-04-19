---
service: "proximity-notification-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Proximity Notification Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Geofence Notification Flow](geofence-notification-flow.md) | synchronous | Mobile client POSTs device location | Accepts location update, evaluates hotzone proximity, applies rate limits, and optionally sends a push notification |
| [Hotzone Batch Generation Flow](hotzone-batch-generation-flow.md) | scheduled | Quartz scheduler trigger | Executes hotzone generator batch job to produce new hotzone deal records in PostgreSQL |
| [Hotzone Management Flow](hotzone-management-flow.md) | synchronous | API call from Proximity UI | CRUD operations on hotzone deals and category campaign configurations |
| [Rate Limit and Suppression Flow](rate-limit-suppression-flow.md) | synchronous | Sub-flow within every geofence request | Checks per-user send log and applies general + type-level rate limits before committing to send a notification |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The [Geofence Notification Flow](geofence-notification-flow.md) spans multiple Continuum services and is the primary cross-service flow for this service. It references the following architecture participants:

- `continuumProximityNotificationService` — orchestrator
- `continuumProximityNotificationRedis` — location/travel state cache
- `continuumProximityNotificationPostgres` — send log persistence
- `continuumAudienceManagementService` — audience targeting
- `continuumCouponsInventoryService` — coupon availability
- `continuumCloInventoryService` — CLO redemption readiness
- `continuumVoucherInventoryService` — voucher sold-out check
- `watsonKv` — deal scoring data
- Rocketman service (stub) — push/email delivery

The DSL dynamic view for this flow is defined in `architecture/views/dynamics/geofence-notification-flow.dsl` but is disabled in federation because several participants are stub-only in the central workspace.
