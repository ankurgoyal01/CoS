---
service: "mls-sentinel"
title: "Voucher Sold Processing"
generated: "2026-03-03"
type: flow
flow_name: "voucher-sold-processing"
flow_type: event-driven
trigger: "jms.queue.mls.VoucherSold MBus queue event"
participants:
  - "messageBus"
  - "continuumMlsSentinelService"
  - "continuumVoucherInventoryService"
  - "mlsSentinelDealIndexDb"
architecture_ref: "dynamic-mls-sentinel-inventory-update-flow"
---

# Voucher Sold Processing

## Summary

When a voucher is sold, the commerce system publishes a `VoucherSold` event to the `jms.queue.mls.VoucherSold` MessageBus queue. MLS Sentinel consumes this event, validates that the inventory and voucher data has propagated to the Voucher Inventory Service (VIS) read-only datasource, and — if valid — emits a fully-validated `mls.VoucherSold` Kafka Command for downstream consumers. If the VIS data is not yet current, the message is nacked and redelivered by MBus after approximately 15 minutes.

## Trigger

- **Type**: event (async)
- **Source**: `jms.queue.mls.VoucherSold` MessageBus queue
- **Frequency**: Per voucher sale transaction; volume scales with Groupon commerce activity

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MessageBus | Delivers VoucherSold event to Sentinel | `messageBus` |
| MLS Sentinel Service | Consumes event, validates, routes command | `continuumMlsSentinelService` |
| Voucher Inventory Service (VIS) | Authoritative source for inventory freshness validation | `continuumVoucherInventoryService` |
| MLS Yang (Kafka consumer) | Downstream consumer of the produced Kafka command | (external to this flow) |

## Steps

1. **Receives VoucherSold event**: The `MBusSourceManager` delivers the `VoucherSold` message payload from `jms.queue.mls.VoucherSold` to the registered VoucherSold `AbstractProcessor`.
   - From: `messageBus`
   - To: `continuumMlsSentinelService` (Message Ingestion Layer)
   - Protocol: MBus / JMS

2. **Parses and deserializes payload**: The `MessageParserImpl` deserializes the MBus message into the typed `VoucherSold` `MessagePayload` object.
   - From: Message Ingestion Layer
   - To: Flow Processing Layer
   - Protocol: internal

3. **Validates entity freshness against VIS**: Calls the Voucher Inventory Service (VIS) to verify that the voucher and inventory unit data has been replicated to the RO datasource. Concurrent VIS calls are bounded by `maxConcurrentVisMessages`. Timeout behavior is controlled by `visCountTimeoutLimit` and optionally the merchant blacklist.
   - From: `continuumMlsSentinelService` (External Client Layer)
   - To: `continuumVoucherInventoryService`
   - Protocol: HTTP (Retrofit2 / RxJava3)

4. **Assembles VoucherSold Command**: If validation succeeds, the Flow Processing Layer assembles a typed `mls.command.message.v_1.Command<VoucherSoldPayload>` containing the validated voucher and merchant data.
   - From: Flow Processing Layer
   - To: RoutingService
   - Protocol: internal

5. **Routes Command to Kafka**: The `RoutingService` publishes the assembled command to the `mls.VoucherSold` Kafka topic using the `KafkaCommandRouter`.
   - From: `continuumMlsSentinelService` (RoutingService)
   - To: `messageBus` (Kafka — `mls.VoucherSold`)
   - Protocol: Kafka 0.9.0.1 (async producer)

6. **Acknowledges MBus message**: The MBus message is acknowledged (committed) once the Kafka Command is successfully produced.
   - From: Flow Processing Layer
   - To: `messageBus`
   - Protocol: MBus / JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| VIS entity not current (replication lag) | Message is nacked; NOT acknowledged to MBus | MBus redelivers after ~15 minutes; no Kafka command emitted |
| VIS count check timeout | If `useMerchantBlacklistOnVisTimeout` enabled, merchant is blacklisted for `merchantBlacklistTimeoutMillis` ms | Message nacked; retried; blacklisted merchant events deferred |
| Kafka producer failure | Error logged via `kafka_message_produce` Steno log; `MlsSentinel-US_KAFKA_PRODUCED` alert fires | Message may be nacked; no command reaches Yang |
| VIS HTTP client error (non-timeout) | Flow processing fails; message nacked | MBus redelivers after ~15 minutes |

## Sequence Diagram

```
MessageBus         -> MlsSentinel (MBusSourceManager): Delivers VoucherSold event
MlsSentinel        -> MlsSentinel (MessageParserImpl): Deserializes payload
MlsSentinel        -> VoucherInventoryService: Validates entity freshness (HTTP)
VoucherInventoryService --> MlsSentinel: Returns current entity count/data
MlsSentinel        -> MlsSentinel (RoutingService): Assembles VoucherSold Command
MlsSentinel        -> Kafka (mls.VoucherSold): Publishes command
MlsSentinel        -> MessageBus: Acknowledges VoucherSold message
```

## Related

- Architecture dynamic view: `dynamic-mls-sentinel-inventory-update-flow`
- Related flows: [Voucher Redeemed Processing](voucher-redeemed-processing.md), [Inventory Update and Backfill](inventory-update-backfill.md)
- Events: [Events](../events.md)
