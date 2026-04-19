---
service: "mls-sentinel"
title: "Merchant Account Changed"
generated: "2026-03-03"
type: flow
flow_name: "merchant-account-changed"
flow_type: event-driven
trigger: "jms.queue.mls.SalesforceCreated or jms.queue.mls.SalesforceUpdate MBus queue event"
participants:
  - "messageBus"
  - "continuumMlsSentinelService"
  - "continuumM3MerchantService"
architecture_ref: "dynamic-mls-sentinel-inventory-update-flow"
---

# Merchant Account Changed

## Summary

When a Salesforce CRM account is created or updated for a Groupon merchant, the integration layer publishes an event to either `jms.queue.mls.SalesforceCreated` or `jms.queue.mls.SalesforceUpdate`. MLS Sentinel consumes these events, resolves the full merchant account data from the M3 Merchant Service, and emits a `mls.MerchantAccountChanged` Kafka Command. This flow keeps the MLS read model (maintained by Yang) synchronized with the CRM state. Manual trigger via `/trigger/salesforce_account_update` is also supported for on-demand re-processing.

## Trigger

- **Type**: event (async), with manual override available
- **Source**: `jms.queue.mls.SalesforceCreated` or `jms.queue.mls.SalesforceUpdate` MBus queue; or `POST /trigger/salesforce_account_update?salesforce_id=<id>` API call
- **Frequency**: Per Salesforce account create or update; infrequent relative to voucher flows

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MessageBus | Delivers Salesforce account events | `messageBus` |
| MLS Sentinel Service | Consumes event, enriches from M3, routes command | `continuumMlsSentinelService` |
| M3 Merchant Service | Authoritative source for merchant account data | `continuumM3MerchantService` |
| MLS Yang (Kafka consumer) | Downstream consumer of `mls.MerchantAccountChanged` command | (external to this flow) |

## Steps

1. **Receives Salesforce event**: `MBusSourceManager` delivers the SalesforceCreated or SalesforceUpdate event to the Salesforce `AbstractProcessor`.
   - From: `messageBus`
   - To: `continuumMlsSentinelService` (Message Ingestion Layer)
   - Protocol: MBus / JMS

2. **Parses Salesforce account payload**: `MessageParserImpl` deserializes the message body to extract the Salesforce account identifier and change details.
   - From: Message Ingestion Layer
   - To: Flow Processing Layer
   - Protocol: internal

3. **Fetches merchant account from M3**: Calls M3 Merchant Service to retrieve the current merchant account data associated with the Salesforce account, ensuring the command payload reflects the authoritative merchant state.
   - From: `continuumMlsSentinelService` (External Client Layer — M3MerchantClient)
   - To: `continuumM3MerchantService`
   - Protocol: HTTP (Retrofit2 / RxJava3)

4. **Assembles MerchantAccountChanged Command**: Builds a typed `Command<MerchantAccountChangedPayload>` with Salesforce and merchant account data.
   - From: Flow Processing Layer
   - To: RoutingService
   - Protocol: internal

5. **Routes Command to Kafka**: `RoutingService` publishes the command to the `mls.MerchantAccountChanged` Kafka topic.
   - From: `continuumMlsSentinelService` (RoutingService)
   - To: `messageBus` (Kafka — `mls.MerchantAccountChanged`)
   - Protocol: Kafka 0.9.0.1

6. **Acknowledges MBus message**: MBus message acknowledged after successful Kafka produce.
   - From: Flow Processing Layer
   - To: `messageBus`
   - Protocol: MBus / JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| M3 Merchant Service unavailable | HTTP client error; flow processing fails; message nacked | MBus redelivers after ~15 minutes |
| Merchant not found in M3 | Flow processing may fail or skip command emit | Message nacked or skipped based on flow handler logic |
| Kafka producer failure | Error logged; Nagios alert fires | Command not delivered to Yang; message may be nacked |
| Manual trigger with unknown Salesforce ID | Flow proceeds; M3 lookup may return no result | No command emitted; HTTP 200 returned to caller |

## Sequence Diagram

```
MessageBus (jms.queue.mls.SalesforceCreated) -> MlsSentinel (MBusSourceManager): Delivers Salesforce event
MlsSentinel -> MlsSentinel (Salesforce Processor): Parses account payload
MlsSentinel -> M3MerchantService: Fetches merchant account data (HTTP)
M3MerchantService --> MlsSentinel: Returns merchant account details
MlsSentinel -> MlsSentinel (RoutingService): Assembles MerchantAccountChanged Command
MlsSentinel -> Kafka (mls.MerchantAccountChanged): Publishes command
MlsSentinel -> MessageBus: Acknowledges Salesforce message
```

## Related

- Architecture dynamic view: `dynamic-mls-sentinel-inventory-update-flow`
- Related flows: [Inventory Update and Backfill](inventory-update-backfill.md)
- API surface: [API Surface](../api-surface.md) — `/trigger/salesforce_account_update`
- Events: [Events](../events.md)
