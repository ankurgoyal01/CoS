---
service: "mls-sentinel"
title: "CLO Transaction Processing"
generated: "2026-03-03"
type: flow
flow_name: "clo-transaction-processing"
flow_type: event-driven
trigger: "jms.topic.clo.redemptions or jms.topic.clo.replay.redemptions MBus topic event"
participants:
  - "messageBus"
  - "continuumMlsSentinelService"
architecture_ref: "dynamic-mls-sentinel-inventory-update-flow"
---

# CLO Transaction Processing

## Summary

The Card-Linked Offers (CLO) platform publishes redemption events to MBus topics when a card-linked offer is triggered by a card transaction. MLS Sentinel consumes these events from `jms.topic.clo.redemptions` (live) and `jms.topic.clo.replay.redemptions` (backfill/replay), assembles a typed CLO transaction command, and publishes it to the `mls.CloTransaction` Kafka topic. Three CLO transaction subtypes are supported: authorization, clearing, and reward. Manual injection of CLO transactions is also available via the trigger API.

## Trigger

- **Type**: event (async), with manual override available
- **Source**: `jms.topic.clo.redemptions` MBus topic; `jms.topic.clo.replay.redemptions` MBus topic; or `POST /trigger/clo_{auth|clear|reward}_transaction` API call
- **Frequency**: Per card transaction that triggers a CLO redemption; replay events during backfill operations

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MessageBus | Delivers CLO redemption topic events | `messageBus` |
| MLS Sentinel Service | Consumes event, assembles CLO command, routes to Kafka | `continuumMlsSentinelService` |
| MLS Yang (Kafka consumer) | Downstream consumer of `mls.CloTransaction` commands | (external to this flow) |

## Steps

1. **Receives CLO redemption event**: `MBusSourceManager` delivers the CLO event from `jms.topic.clo.redemptions` or `jms.topic.clo.replay.redemptions` to the CLO `AbstractProcessor`. For the manual flow, the trigger API receives a `POST /trigger/clo_{subtype}_transaction` request with a `CloAuthTransactionMessage`, `CloClearTransactionMessage`, or `CloRewardTransactionMessage` body.
   - From: `messageBus` (or inbound HTTP trigger)
   - To: `continuumMlsSentinelService` (Message Ingestion Layer / Resource API Layer)
   - Protocol: MBus / JMS (or HTTP)

2. **Parses CLO transaction type**: Identifies the CLO transaction subtype (authorization, clearing, or reward) from the message payload. The `preClaim` flag in the body differentiates pre-claim vs. standard processing.
   - From: Message Ingestion Layer
   - To: Flow Processing Layer
   - Protocol: internal

3. **Assembles CloTransaction Command**: Builds a typed `Command<CloTransactionPayload>` with the full CLO transaction data.
   - From: Flow Processing Layer
   - To: RoutingService
   - Protocol: internal

4. **Routes Command to Kafka**: `RoutingService` publishes the command to the `mls.CloTransaction` Kafka topic.
   - From: `continuumMlsSentinelService` (RoutingService)
   - To: `messageBus` (Kafka — `mls.CloTransaction`)
   - Protocol: Kafka 0.9.0.1

5. **Acknowledges MBus message**: MBus topic message is acknowledged after successful Kafka produce.
   - From: Flow Processing Layer
   - To: `messageBus`
   - Protocol: MBus / JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kafka producer failure | Error logged; `MlsSentinel-US_KAFKA_PRODUCED` Nagios alert fires | MBus message may be nacked; command not delivered to Yang |
| Malformed CLO payload | `MessageParserImpl` deserialization failure; message nacked | MBus redelivers message; persistent failures require DLQ retry |
| Manual trigger API error | HTTP 500 returned; no MBus involvement | Caller must retry the trigger API call |

## Sequence Diagram

```
MessageBus (jms.topic.clo.redemptions) -> MlsSentinel (MBusSourceManager): Delivers CLO redemption event
MlsSentinel -> MlsSentinel (CLO Flow Processor): Identifies transaction subtype
MlsSentinel -> MlsSentinel (RoutingService): Assembles CloTransaction Command
MlsSentinel -> Kafka (mls.CloTransaction): Publishes command
MlsSentinel -> MessageBus: Acknowledges CLO topic message
```

**Manual trigger path:**
```
External Caller -> MlsSentinel (/trigger/clo_auth_transaction): POST with CloAuthTransactionMessage body
MlsSentinel -> MlsSentinel (CLO Flow Processor): Processes auth transaction
MlsSentinel -> Kafka (mls.CloTransaction): Publishes command
MlsSentinel --> External Caller: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-mls-sentinel-inventory-update-flow`
- Related flows: [Voucher Sold Processing](voucher-sold-processing.md), [Merchant Account Changed](merchant-account-changed.md)
- API surface: [API Surface](../api-surface.md) — `/trigger/clo_*` endpoints
- Events: [Events](../events.md)
