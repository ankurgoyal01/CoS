---
service: "message2ledger"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

message2ledger is a pure consumer on the MBus (JMS-based message bus). It subscribes to six topics spanning order transactional ledger events and inventory unit update events across NA and EMEA regions. The service does not publish any events to MBus. All inbound events are persisted to `continuumMessage2LedgerMysql` and processed asynchronously via the Async Task Processor.

## Published Events

> Not applicable. message2ledger does not publish any events to MBus or any other messaging system.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `Orders.TransactionalLedgerEvents` (NA) | Order transactional ledger event | MBus Ingress — OrdersMessageProcessor | Persists message envelope, enqueues processing attempt |
| `Orders.TransactionalLedgerEvents` (EMEA) | Order transactional ledger event | MBus Ingress — OrdersMessageProcessor | Persists message envelope, enqueues processing attempt |
| `InventoryUnits.Updated.Vis` (NA) | VIS inventory unit update | MBus Ingress — InventoryMessageProcessor | Persists message envelope, enqueues processing attempt |
| `InventoryUnits.Updated.Vis` (EMEA) | VIS inventory unit update | MBus Ingress — InventoryMessageProcessor | Persists message envelope, enqueues processing attempt |
| `InventoryUnits.Updated.Tpis` (NA) | TPIS inventory unit update | MBus Ingress — InventoryMessageProcessor | Persists message envelope, enqueues processing attempt |
| `InventoryUnits.Updated.Tpis` (EMEA) | TPIS inventory unit update | MBus Ingress — InventoryMessageProcessor | Persists message envelope, enqueues processing attempt |

### Orders.TransactionalLedgerEvents Detail

- **Topic**: `Orders.TransactionalLedgerEvents` (NA and EMEA)
- **Handler**: `m2l_mbusIngress` — OrdersMessageProcessor; on receipt, stores message envelope in `continuumMessage2LedgerMysql` and enqueues a processing attempt via `m2l_processingOrchestrator`
- **Idempotency**: Processing attempts are tracked per message in MySQL; duplicate delivery is handled by attempt deduplication logic
- **Error handling**: Failed attempts are retried by the Quartz/KillBill Queue scheduler; messages can be manually retried via `/admin/messages/retry/{id}` or replayed via the reconciliation flow
- **Processing order**: Unordered (asynchronous queue-based processing)

### InventoryUnits.Updated.Vis Detail

- **Topic**: `InventoryUnits.Updated.Vis` (NA and EMEA)
- **Handler**: `m2l_mbusIngress` — InventoryMessageProcessor; stores message envelope and enqueues attempt; Processing Orchestrator subsequently calls `m2l_inventoryEnrichment` for VIS unit/product details and `m2l_accountingIntegration` to post the ledger entry
- **Idempotency**: Attempt tracking in MySQL guards against double-posting
- **Error handling**: Retry via Quartz scheduler; manual retry via admin API
- **Processing order**: Unordered

### InventoryUnits.Updated.Tpis Detail

- **Topic**: `InventoryUnits.Updated.Tpis` (NA and EMEA)
- **Handler**: `m2l_mbusIngress` — InventoryMessageProcessor; same pipeline as VIS events but routes enrichment calls to `continuumThirdPartyInventoryService`
- **Idempotency**: Attempt tracking in MySQL guards against double-posting
- **Error handling**: Retry via Quartz scheduler; manual retry via admin API
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found for a dedicated DLQ configuration. Failed messages are retained in `continuumMessage2LedgerMysql` with error status and are eligible for retry via the Quartz scheduler or admin retry endpoints. See [Admin Retry Orchestration](flows/admin-retry-orchestration.md) and [Scheduled Reconciliation Replay](flows/scheduled-reconciliation-replay.md) for retry/replay flows.
