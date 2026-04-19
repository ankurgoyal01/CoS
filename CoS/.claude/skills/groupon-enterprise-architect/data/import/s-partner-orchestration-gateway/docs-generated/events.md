---
service: "s-partner-orchestration-gateway"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

S-POG consumes asynchronous inventory unit update events from the Groupon MessageBus (MBus/JMS). Two separate consumer subscriptions exist — one for Voucher Inventory Service (VIS) events and one for Third-Party Inventory Service (TPIS) events. The service does not publish any outbound async events; all outbound communication is synchronous HTTP/REST.

## Published Events

> No evidence found in codebase. S-POG does not publish events to the message bus.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| VIS inventory unit update topic | `InventoryUnitUpdateMessageDto` | `InventoryUnitUpdateMessageProcessor` | Fetches updated unit from VIS, syncs Google Wallet offer object state and barcode |
| TPIS inventory unit update topic | `InventoryUnitUpdateMessageDto` | `InventoryUnitUpdateMessageProcessor` | Fetches updated unit from TPIS, syncs Google Wallet offer object state |

### Inventory Unit Update Event Detail

- **Topic**: VIS and TPIS inventory unit update topics (exact topic names configured via `messagebus` config block, not hardcoded in source)
- **Handler**: `spog.attribution.mbus.consumer.InventoryUnitUpdateMessageProcessor` — extracts inventory unit IDs from the payload, delegates to all registered `UnitUpdateOrchestrator` implementations (currently `WalletInventoryUnitUpdateOrchestrator`)
- **Message schema** (`spog.common.mbus.messages.InventoryUnitUpdateMessageDto`):
  - `payload.inventoryUnits[]` — list of updated inventory units
  - `payload.inventoryUnits[].inventoryUnitId` — UUID (required)
  - `payload.inventoryUnits[].inventoryServiceId` — string (VIS or TPIS identifier)
  - `payload.inventoryUnits[].inventoryProductId` — UUID
  - `payload.inventoryUnits[].updatedAt` — ZonedDateTime (required)
- **Processing**: For each unit ID in the message, the orchestrator checks if the unit has a corresponding wallet unit record (`wallet_units` table). Units without a wallet mapping are skipped. For matched units, the orchestrator fetches the current unit state from VIS and retrieves the Google Wallet offer object. It then either marks the offer as `COMPLETED` (if the unit has been redeemed) or updates the barcode value (if a redemption code is now available and the current barcode is invalid).
- **Idempotency**: Partially idempotent — checks wallet unit existence and offer object state before making updates; duplicate messages trigger re-checks but produce no side effects if state is already consistent.
- **Error handling**: Per-unit exceptions during Google Wallet API calls are caught and logged as warnings/errors; processing continues for remaining units. The message is acknowledged after processing.
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found in codebase. DLQ configuration is managed externally through the MBus / JTier message bus infrastructure.
