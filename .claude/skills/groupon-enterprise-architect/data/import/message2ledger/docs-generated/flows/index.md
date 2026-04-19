---
service: "message2ledger"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for message2ledger.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Order to Ledger Processing](order-to-ledger-processing.md) | event-driven | `Orders.TransactionalLedgerEvents` MBus event (NA/EMEA) | Consumes an order transactional ledger event, enriches with cost details, and posts a ledger entry to the Accounting Service |
| [Inventory Unit Update Processing](inventory-unit-update-processing.md) | event-driven | `InventoryUnits.Updated.Vis` or `InventoryUnits.Updated.Tpis` MBus event (NA/EMEA) | Consumes an inventory unit update event, enriches with unit/product details from VIS or TPIS, and posts a ledger entry |
| [Manual Message Replay](manual-message-replay.md) | synchronous | POST `/messages` or operator action via admin API | Replays a specific message through the ledger pipeline on demand; used for recovery and migration scenarios |
| [Scheduled Reconciliation Replay](scheduled-reconciliation-replay.md) | scheduled | Quartz scheduler (periodic) | Queries EDW for messages that should be replayed, identifies gaps in ledger processing, and re-enqueues affected messages |
| [Admin Retry Orchestration](admin-retry-orchestration.md) | synchronous | POST `/admin/messages/retry/{id}` | Operator-initiated retry of a specific failed message; reads current attempt state and re-enqueues for processing |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The order-to-ledger and inventory-unit-update flows span multiple Continuum services. The central architecture dynamic view `dynamic-m2l-message-to-ledger-flow` captures the container-level sequence from MBus ingress through MySQL persistence, inventory enrichment, and Accounting Service posting. See [Architecture Context](../architecture-context.md) for C4 diagram references.
