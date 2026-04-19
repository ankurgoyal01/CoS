---
service: "mpp-service-v2"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus, jms]
---

# Events

## Overview

MPP Service V2 is a consumer-only participant in the message bus (JMS/MBus). It subscribes to three topics: place data updates, inventory product updates, and deal distribution events. All three consumers are implemented as `MessageProcessor<String>` instances registered via the JTier `jtier-messagebus-client` library. Topic names are defined in `MBusKey` constants. The `MBusConfig` controls whether the message bus integration is enabled (`isEnable`) and optionally whether writes are forwarded to M3 (`isWriteToM3`). The service does not publish any events to the message bus.

## Published Events

> No evidence found in codebase. MPP Service V2 does not publish events to the message bus.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `placeDataUpdate` | Place update notification | `PlaceUpdateProcessor` | Writes place UUID to update queue in DB (`PlaceUpdateStatusDaoService`, status `QUEUE`) |
| `inventoryProductsUpdate` | Inventory product update | `InventoryProductProcessor` | Resolves location UUIDs via VIS API and marks corresponding slugs as indexed |
| `dealDistribution` | Deal distribution event | `DealDistributionProcessor` | Triggers slug indexing updates for affected places |

### `placeDataUpdate` Detail

- **Topic**: `placeDataUpdate` (constant `MBusKey.PLACE_DATA_UPDATE`)
- **Handler**: `PlaceUpdateProcessor` — parses `PlaceUpdateMessage` → `PlaceUpdatePayload` to extract the place UUID, then upserts the place into the update queue with status `QUEUE` via `PlaceUpdateStatusDaoService`
- **Idempotency**: Checks `isPlaceUpdateQueuing(placeUuid)` before upsert to avoid duplicate queue entries
- **Error handling**: Logs and returns on JSON parse failure; continues processing on invalid message shape
- **Processing order**: Unordered

### `inventoryProductsUpdate` Detail

- **Topic**: `inventoryProductsUpdate` (constant `MBusKey.INV_PROD_UPDATE`)
- **Handler**: `InventoryProductProcessor` — deserializes `InventProdsUpdateMsg`, extracts inventory product UUIDs, calls VIS API (`VisClient.getLocationUuidsByProductInventoryIds`) to resolve location UUIDs, then calls `SlugDaoService.indexPlaceByPlaceUuids` to mark affected slugs
- **Idempotency**: Re-indexing slugs for the same location UUID is idempotent by design
- **Error handling**: Logs and returns on JSON parse failure; skips processing for empty inventory product lists
- **Processing order**: Unordered

### `dealDistribution` Detail

- **Topic**: `dealDistribution` (constant `MBusKey.DEAL_DISTRIBUTION`)
- **Handler**: `DealDistributionProcessor` — triggers slug indexing updates for places associated with the distributed deal
- **Idempotency**: Slug indexing updates are idempotent
- **Error handling**: Handled via JTier message bus retry mechanisms
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found in codebase for explicitly configured DLQ names. Dead letter handling is managed by the JTier `jtier-messagebus-client` infrastructure layer.
