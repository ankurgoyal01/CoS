---
service: "voucher-inventory-jtier"
title: "Inventory Event Processing"
generated: "2026-03-03"
type: flow
flow_name: "inventory-event-processing"
flow_type: event-driven
trigger: "MessageBus message on InventoryUnits.Updated.* or InventoryProducts.Updated.* topics"
participants:
  - "continuumVoucherInventoryWorker"
  - "messageBus"
  - "continuumVoucherInventoryProductDb"
  - "continuumVoucherInventoryUnitsDb"
  - "continuumVoucherInventoryRedis"
architecture_ref: "components-voucherInventoryWorker"
---

# Inventory Event Processing

## Summary

The Worker container subscribes to four inventory update topics on MessageBus and processes incoming events to keep the MySQL databases and Redis cache synchronized with upstream inventory changes. This flow handles both unit-level updates (`InventoryUnits.Updated.*`) and product-level updates (`InventoryProducts.Updated.*`) from two source systems (Voucher and VIS). The MessageBus Consumer dispatches each message to the appropriate Message Processor, which applies the update via the Inventory Processing Service.

## Trigger

- **Type**: event
- **Source**: External publishing services (VIS 2.0, Order/Voucher systems) via MessageBus topics
- **Frequency**: Continuous; driven by inventory change rate across Groupon's platform

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MessageBus | Source of inventory update events | `messageBus` |
| MessageBus Consumer | Polls and receives messages from subscribed topics | `continuumVoucherInventoryWorker` |
| Message Processors | Routes messages to appropriate handlers | `continuumVoucherInventoryWorker` |
| Inventory Processing Service | Applies inventory updates; orchestrates DB and cache writes | `continuumVoucherInventoryWorker` |
| Inventory DAOs (Worker) | Reads/writes product and unit records in MySQL | `continuumVoucherInventoryProductDb`, `continuumVoucherInventoryUnitsDb` |
| Redis Cache Client (Worker) | Refreshes cache entries after DB update | `continuumVoucherInventoryRedis` |

## Steps

1. **Polls MessageBus**: MessageBus Consumer polls each subscribed topic at the configured `mbusConsumerPollTime` interval (10,000ms) using durable subscriptions
   - From: `continuumVoucherInventoryWorker` (MessageBus Consumer)
   - To: `messageBus`
   - Protocol: JMS/STOMP (port 61613)

2. **Receives inventory update message**: MessageBus Consumer receives an inventory update event from one of the four topics:
   - `jms.topic.InventoryUnits.Updated.Voucher` (subscription: `vis_jtier` / `vis_jtier_cloud`)
   - `jms.topic.InventoryProducts.Updated.Voucher` (subscription: `vis_jtier` / `vis_jtier_cloud`)
   - `jms.topic.InventoryUnits.Updated.Vis` (subscription: `vis_jtier` / `vis_jtier_cloud`)
   - `jms.topic.InventoryProducts.Updated.Vis` (subscription: `vis_jtier_na` / `vis_jtier_cloud_na`)
   - From: `messageBus`
   - To: `continuumVoucherInventoryWorker` (MessageBus Consumer)
   - Protocol: JMS/STOMP

3. **Dispatches to Message Processor**: MessageBus Consumer dispatches the received message to the appropriate Message Processor based on topic
   - From: MessageBus Consumer (in-process)
   - To: Message Processors (in-process)
   - Protocol: direct

4. **Routes to Inventory Processing Service**: Message Processor passes the parsed inventory update to the Inventory Processing Service for business logic application
   - From: Message Processors (in-process)
   - To: Inventory Processing Service (in-process)
   - Protocol: direct

5. **Reads current state from DB**: Inventory Processing Service loads current product or unit data via Inventory DAOs to determine the delta
   - From: `continuumVoucherInventoryWorker` (Inventory DAOs)
   - To: `continuumVoucherInventoryProductDb` or `continuumVoucherInventoryUnitsDb`
   - Protocol: JDBI/MySQL

6. **Writes updated state to DB**: Inventory Processing Service applies the update via Inventory DAOs
   - From: `continuumVoucherInventoryWorker` (Inventory DAOs)
   - To: `continuumVoucherInventoryProductDb` or `continuumVoucherInventoryUnitsDb`
   - Protocol: JDBI/MySQL

7. **Refreshes Redis cache**: Redis Cache Client updates the cache entry for the affected product/unit with the new state
   - From: `continuumVoucherInventoryWorker` (Redis Cache Client)
   - To: `continuumVoucherInventoryRedis`
   - Protocol: Redis (TTL: 10,800s for products, 600s for unit sold counts)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MessageBus connectivity lost | Durable subscription preserves messages; consumer reconnects on recovery | Messages queued in MessageBus; processed after reconnection |
| MySQL write failure | No explicit retry logic documented | Update dropped for that message; cache may be stale until next event |
| Redis write failure | No explicit retry logic documented | DB updated but cache not refreshed; next API cache miss will re-populate |
| Message parse error | No explicit DLQ configured | No evidence found; message may be skipped |

## Sequence Diagram

```
MessageBus         -> WorkerMbusConsumer:       DELIVER InventoryProducts.Updated.Voucher
WorkerMbusConsumer -> WorkerMessageProcessors:  dispatch message
WorkerMessageProcessors -> WorkerInventoryService: apply inventory update
WorkerInventoryService -> WorkerInventoryDaos:  SELECT current product/unit state
WorkerInventoryDaos    -> ProductDB/UnitsDB:    SELECT query
ProductDB/UnitsDB      --> WorkerInventoryDaos: current data
WorkerInventoryDaos    --> WorkerInventoryService: current data
WorkerInventoryService -> WorkerInventoryDaos:  UPDATE product/unit record
WorkerInventoryDaos    -> ProductDB/UnitsDB:    UPDATE query
WorkerInventoryService -> WorkerRedisCacheClient: REFRESH cache entry
WorkerRedisCacheClient -> Redis:                SET updated inventory (TTL)
Redis              --> WorkerRedisCacheClient:  OK
```

## Related

- Architecture ref: `components-voucherInventoryWorker`
- Related flows: [Sold-Out Error Processing](sold-out-error-processing.md), [Inventory Product Lookup](inventory-product-lookup.md)
- Events: [Events](../events.md)
