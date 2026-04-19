---
service: "mls-sentinel"
title: "Voucher Redeemed Processing"
generated: "2026-03-03"
type: flow
flow_name: "voucher-redeemed-processing"
flow_type: event-driven
trigger: "jms.queue.mls.VoucherRedeemed MBus queue event"
participants:
  - "messageBus"
  - "continuumMlsSentinelService"
  - "continuumVoucherInventoryService"
architecture_ref: "dynamic-mls-sentinel-inventory-update-flow"
---

# Voucher Redeemed Processing

## Summary

When a voucher is redeemed by a merchant or consumer, the redemption system publishes a `VoucherRedeemed` event to the `jms.queue.mls.VoucherRedeemed` MessageBus queue. MLS Sentinel consumes this event, validates the redemption entity against VIS, and emits a validated `mls.VoucherRedeemed` Kafka Command. The retry-on-lag behavior is identical to the [Voucher Sold flow](voucher-sold-processing.md).

## Trigger

- **Type**: event (async)
- **Source**: `jms.queue.mls.VoucherRedeemed` MessageBus queue
- **Frequency**: Per voucher redemption; volume scales with merchant redemption activity

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MessageBus | Delivers VoucherRedeemed event to Sentinel | `messageBus` |
| MLS Sentinel Service | Consumes event, validates, routes command | `continuumMlsSentinelService` |
| Voucher Inventory Service (VIS) | Authoritative source for inventory freshness validation | `continuumVoucherInventoryService` |
| MLS Yang (Kafka consumer) | Downstream consumer of the produced Kafka command | (external to this flow) |

## Steps

1. **Receives VoucherRedeemed event**: `MBusSourceManager` delivers the message from `jms.queue.mls.VoucherRedeemed` to the VoucherRedeemed `AbstractProcessor`.
   - From: `messageBus`
   - To: `continuumMlsSentinelService` (Message Ingestion Layer)
   - Protocol: MBus / JMS

2. **Parses and deserializes payload**: `MessageParserImpl` deserializes the message into a typed `VoucherRedeemed` `MessagePayload`.
   - From: Message Ingestion Layer
   - To: Flow Processing Layer
   - Protocol: internal

3. **Validates entity freshness against VIS**: Calls VIS to confirm the redemption record has propagated to the RO datasource. Same concurrency and timeout controls as the Voucher Sold flow.
   - From: `continuumMlsSentinelService` (External Client Layer)
   - To: `continuumVoucherInventoryService`
   - Protocol: HTTP (Retrofit2 / RxJava3)

4. **Assembles VoucherRedeemed Command**: If VIS confirms freshness, assembles the typed Kafka Command with redemption payload.
   - From: Flow Processing Layer
   - To: RoutingService
   - Protocol: internal

5. **Routes Command to Kafka**: `RoutingService` publishes the command to the `mls.VoucherRedeemed` Kafka topic.
   - From: `continuumMlsSentinelService` (RoutingService)
   - To: `messageBus` (Kafka — `mls.VoucherRedeemed`)
   - Protocol: Kafka 0.9.0.1

6. **Acknowledges MBus message**: MBus message acknowledged after successful Kafka produce.
   - From: Flow Processing Layer
   - To: `messageBus`
   - Protocol: MBus / JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| VIS entity not current | Message nacked; not acknowledged | MBus redelivers after ~15 minutes; no Kafka command emitted |
| VIS timeout | Merchant blacklist applied if configured | Message nacked; retried after backoff |
| Kafka producer failure | Error logged; `MlsSentinel-US_KAFKA_PRODUCED` alert fires | Message may be nacked; command not delivered to Yang |

## Sequence Diagram

```
MessageBus            -> MlsSentinel (MBusSourceManager): Delivers VoucherRedeemed event
MlsSentinel           -> MlsSentinel (MessageParserImpl): Deserializes payload
MlsSentinel           -> VoucherInventoryService: Validates entity freshness (HTTP)
VoucherInventoryService --> MlsSentinel: Returns current entity data
MlsSentinel           -> MlsSentinel (RoutingService): Assembles VoucherRedeemed Command
MlsSentinel           -> Kafka (mls.VoucherRedeemed): Publishes command
MlsSentinel           -> MessageBus: Acknowledges VoucherRedeemed message
```

## Related

- Architecture dynamic view: `dynamic-mls-sentinel-inventory-update-flow`
- Related flows: [Voucher Sold Processing](voucher-sold-processing.md), [Inventory Update and Backfill](inventory-update-backfill.md)
- Events: [Events](../events.md)
