---
service: "voucher-inventory-jtier"
title: "Sold-Out Error Processing"
generated: "2026-03-03"
type: flow
flow_name: "sold-out-error-processing"
flow_type: event-driven
trigger: "MessageBus message on jms.topic.Orders.Vouchers.SoldOutError"
participants:
  - "continuumVoucherInventoryWorker"
  - "messageBus"
  - "continuumVoucherInventoryProductDb"
  - "continuumVoucherInventoryUnitsDb"
  - "continuumVoucherInventoryRedis"
architecture_ref: "components-voucherInventoryWorker"
---

# Sold-Out Error Processing

## Summary

When the Orders Service detects that a voucher product has been sold out, it publishes a `Orders.Vouchers.SoldOutError` event to MessageBus. The Voucher Inventory Worker consumes this event and updates the inventory sold-out state in the MySQL databases and Redis cache. This ensures that downstream inventory lookups reflect the sold-out status promptly, preventing further purchases of exhausted inventory.

## Trigger

- **Type**: event
- **Source**: Orders Service (external publisher) via `jms.topic.Orders.Vouchers.SoldOutError`
- **Frequency**: On demand; triggered when an order attempt detects a sold-out condition

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MessageBus | Delivers sold-out error event | `messageBus` |
| MessageBus Consumer | Polls and receives sold-out error messages | `continuumVoucherInventoryWorker` |
| Message Processors | Routes sold-out message to Inventory Processing Service | `continuumVoucherInventoryWorker` |
| Inventory Processing Service | Applies sold-out status update to DB and cache | `continuumVoucherInventoryWorker` |
| Inventory DAOs (Worker) | Updates product/unit sold-out state in MySQL | `continuumVoucherInventoryProductDb`, `continuumVoucherInventoryUnitsDb` |
| Redis Cache Client (Worker) | Invalidates or updates sold-out cache entry | `continuumVoucherInventoryRedis` |

## Steps

1. **Receives sold-out event**: MessageBus Consumer receives a message from `jms.topic.Orders.Vouchers.SoldOutError` on durable subscription `vis_jtier` (on-prem) or `vis_jtier_cloud` (cloud)
   - From: `messageBus`
   - To: `continuumVoucherInventoryWorker` (MessageBus Consumer)
   - Protocol: JMS/STOMP (port 61613)

2. **Dispatches to Message Processor**: MessageBus Consumer routes the sold-out message to the dedicated Message Processor for sold-out events
   - From: MessageBus Consumer (in-process)
   - To: Message Processors (in-process)
   - Protocol: direct

3. **Routes to Inventory Processing Service**: Message Processor passes the parsed sold-out payload (product ID, unit count information) to Inventory Processing Service
   - From: Message Processors (in-process)
   - To: Inventory Processing Service (in-process)
   - Protocol: direct

4. **Updates sold-out state in MySQL**: Inventory Processing Service applies the sold-out update via Inventory DAOs to the relevant product and unit tables
   - From: `continuumVoucherInventoryWorker` (Inventory DAOs)
   - To: `continuumVoucherInventoryProductDb` and/or `continuumVoucherInventoryUnitsDb`
   - Protocol: JDBI/MySQL

5. **Refreshes Redis cache**: Redis Cache Client updates the cached inventory entry to reflect the sold-out status, using the unit sold count TTL (600 seconds)
   - From: `continuumVoucherInventoryWorker` (Redis Cache Client)
   - To: `continuumVoucherInventoryRedis`
   - Protocol: Redis

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MessageBus connectivity lost | Durable subscription preserves messages until reconnection | Sold-out update delayed but not lost |
| MySQL update failure | No explicit retry logic documented | Sold-out state may be inconsistent until next event |
| Redis update failure | No explicit retry logic documented | Cache may serve stale (non-sold-out) data until TTL expiry (600s) or next cache refresh |

## Sequence Diagram

```
OrdersService      -> MessageBus:               PUBLISH Orders.Vouchers.SoldOutError
MessageBus         -> WorkerMbusConsumer:        DELIVER Orders.Vouchers.SoldOutError
WorkerMbusConsumer -> WorkerMessageProcessors:   dispatch sold-out message
WorkerMessageProcessors -> WorkerInventoryService: apply sold-out update
WorkerInventoryService -> WorkerInventoryDaos:   UPDATE sold-out status
WorkerInventoryDaos    -> ProductDB/UnitsDB:     UPDATE sold-out fields
WorkerInventoryService -> WorkerRedisCacheClient: REFRESH sold-out cache entry (TTL: 600s)
WorkerRedisCacheClient -> Redis:                 SET sold-out status
Redis              --> WorkerRedisCacheClient:   OK
```

## Related

- Architecture ref: `components-voucherInventoryWorker`
- Related flows: [Inventory Event Processing](inventory-event-processing.md), [Inventory Product Lookup](inventory-product-lookup.md)
- Events: [Events](../events.md)
