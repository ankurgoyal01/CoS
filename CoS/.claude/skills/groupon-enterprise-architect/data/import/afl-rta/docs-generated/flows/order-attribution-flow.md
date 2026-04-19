---
service: "afl-rta"
title: "Order Attribution Flow"
generated: "2026-03-03"
type: flow
flow_name: "order-attribution-flow"
flow_type: event-driven
trigger: "dealPurchase event consumed from Kafka janus-tier2 topic"
participants:
  - "continuumJanusTier2Topic"
  - "continuumAflRtaService"
  - "continuumAflRtaMySql"
  - "continuumOrdersService"
  - "continuumMarketingDealService"
  - "messageBus"
architecture_ref: "dynamic-afl-rta-order-aflRta_clickAttribution"
---

# Order Attribution Flow

## Summary

When a Groupon customer completes a deal purchase, Janus produces a `dealPurchase` event on the `janus-tier2` Kafka topic. AFL RTA consumes this event, looks up the customer's click history stored in MySQL by their bcookie, and determines whether the purchase falls within the 7-day referral window for any marketing channel. If attributed, the service enriches the order with data from the Orders API and MDS (deal taxonomy), then publishes the attributed order to MBus for downstream Commission Junction and partner channel processing. The attributed order is also persisted to MySQL for audit and deduplication.

## Trigger

- **Type**: event
- **Source**: `janus-tier2` Kafka topic (event type: `dealPurchase`); produced by the Janus data-engineering pipeline
- **Frequency**: Per-request (continuous; one record per qualifying deal purchase across all Groupon platforms)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Janus Tier 2 Kafka Topic | Source of inbound `dealPurchase` events | `continuumJanusTier2Topic` |
| RtaPollingConsumer | Polls Kafka and forwards messages for processing | `continuumAflRtaService` |
| EventProcessor | Deserializes the Kafka record and routes to the order attribution strategy | `continuumAflRtaService` |
| OrderAttributionStrategy | Correlates purchase with click history; drives attribution decision | `continuumAflRtaService` |
| ClicksService | Provides click history lookup by bcookie | `continuumAflRtaService` |
| OrderRegistrationFactory | Selects the appropriate order registration handler by channel | `continuumAflRtaService` |
| MBusOrderRegistration | Publishes attributed orders to MBus for enabled channels | `continuumAflRtaService` |
| LoggingOrderRegistration | Fallback: logs and stores attributed orders when MBus is unavailable | `continuumAflRtaService` |
| OrderService | Enriches attributed orders with API data and persists them | `continuumAflRtaService` |
| LegacyOrderIdResolver | Resolves legacy numeric order IDs from Orders v1 | `continuumAflRtaService` |
| OrderUuidResolver | Resolves UUID-based order IDs from Orders v2 | `continuumAflRtaService` |
| OrdersApiService | Fetches customer status (new/returning) from Orders API | `continuumAflRtaService` |
| MDSHttpAdapter | Fetches deal taxonomy and option details from MDS | `continuumAflRtaService` |
| AFL RTA MySQL | Stores click history (read) and attributed order records (write) | `continuumAflRtaMySql` |
| Orders Service | Source of order details and customer status | `continuumOrdersService` |
| Marketing Deal Service (MDS) | Source of deal taxonomy and deal option metadata | `continuumMarketingDealService` |
| Message Bus (MBus) | Receives attributed order events for downstream partner processing | `messageBus` |

## Steps

1. **Poll Kafka record**: `RtaPollingConsumer` polls a batch of records from the `janus-tier2` Kafka topic.
   - From: `continuumJanusTier2Topic`
   - To: `RtaPollingConsumer` (within `continuumAflRtaService`)
   - Protocol: Kafka (TLS, kafka-clients 2.7.0)

2. **Dispatch to EventProcessor**: The polled message payload is handed to `EventProcessor` for deserialization and routing.
   - From: `RtaPollingConsumer`
   - To: `EventProcessor`
   - Protocol: direct (in-process)

3. **Deserialize and route**: `EventProcessor` uses `janus-thin-mapper` to deserialize the Avro/JSON payload and identifies the event type as `dealPurchase`, routing to `OrderAttributionStrategy`.
   - From: `EventProcessor`
   - To: `OrderAttributionStrategy`
   - Protocol: direct (in-process)

4. **Read click history**: `OrderAttributionStrategy` calls `ClicksService` to look up stored click records in MySQL by the bcookie from the purchase event, checking for any qualifying click within the 7-day referral window.
   - From: `OrderAttributionStrategy`
   - To: `ClicksService`
   - Protocol: direct (in-process)

5. **Click history lookup in MySQL**: `ClicksService` queries the `continuumAflRtaMySql` clicks table by bcookie.
   - From: `ClicksService`
   - To: `continuumAflRtaMySql`
   - Protocol: JDBC

6. **Resolve order registration handler**: `OrderAttributionStrategy` passes the attribution result to `OrderRegistrationFactory`, which selects either `MBusOrderRegistration` (for channels with MBus publishing enabled) or `LoggingOrderRegistration` (fallback).
   - From: `OrderAttributionStrategy`
   - To: `OrderRegistrationFactory`
   - Protocol: direct (in-process)

7. **Persist attributed order (MBus path)**: `MBusOrderRegistration` calls `OrderService` to enrich and persist the attributed order.
   - From: `MBusOrderRegistration`
   - To: `OrderService`
   - Protocol: direct (in-process)

8. **Resolve order ID**: `OrderService` resolves the order identifier — using `LegacyOrderIdResolver` for numeric v1 order IDs or `OrderUuidResolver` for UUID v2 order IDs — by calling the Orders API.
   - From: `OrderService`
   - To: `LegacyOrderIdResolver` or `OrderUuidResolver`
   - Protocol: direct (in-process)

9. **Fetch customer status**: `OrderService` calls `OrdersApiService` to determine whether the customer is new or returning.
   - From: `OrderService`
   - To: `OrdersApiService`
   - Protocol: direct (in-process) then HTTPS/JSON to `continuumOrdersService`

10. **Fetch deal metadata**: `OrderService` calls `MDSHttpAdapter` to retrieve deal taxonomy and deal option details for the purchased deal.
    - From: `OrderService`
    - To: `MDSHttpAdapter`
    - Protocol: direct (in-process) then HTTPS/JSON to `continuumMarketingDealService`

11. **Write attributed order to MySQL**: `OrderService` inserts the enriched attributed order record into `continuumAflRtaMySql` for audit and deduplication.
    - From: `OrderService`
    - To: `continuumAflRtaMySql`
    - Protocol: JDBC

12. **Publish to MBus**: `MBusOrderRegistration` publishes the attributed order payload to `messageBus` via MBus/JMS for downstream partner channel processing.
    - From: `MBusOrderRegistration`
    - To: `messageBus`
    - Protocol: MBus/JMS

13. **Commit Kafka offset**: `RtaPollingConsumer` commits the offset for the successfully processed record to Kafka.
    - From: `RtaPollingConsumer`
    - To: `continuumJanusTier2Topic`
    - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No qualifying click found in 7-day window | Attribution strategy skips MBus publish | Purchase event is processed without attribution; offset is committed |
| `continuumOrdersService` unavailable | `failsafe` retry with back-off | After retries exhausted, falls back to `LoggingOrderRegistration` |
| `continuumMarketingDealService` unavailable | `failsafe` retry; `cache2k` serves cached deal data if available | After retries exhausted, falls back to `LoggingOrderRegistration` |
| MBus publish failure | Exception caught by `MBusOrderRegistration` | Falls back to `LoggingOrderRegistration` which logs and stores the attributed order |
| MySQL write failure | Exception propagates; offset not committed | Consumer retries from the same offset on next poll cycle |
| Kafka connectivity loss | Consumer polling stalls | Processing resumes from last committed offset on reconnect |

## Sequence Diagram

```
janus-tier2 (Kafka) -> RtaPollingConsumer: dealPurchase event record
RtaPollingConsumer -> EventProcessor: dispatch message payload
EventProcessor -> OrderAttributionStrategy: route dealPurchase event
OrderAttributionStrategy -> ClicksService: read click history for bcookie
ClicksService -> continuumAflRtaMySql: SELECT clicks by bcookie (JDBC)
continuumAflRtaMySql --> ClicksService: click history result set
OrderAttributionStrategy -> OrderRegistrationFactory: resolve registration handler
OrderRegistrationFactory -> MBusOrderRegistration: create MBus handler (enabled channels)
MBusOrderRegistration -> OrderService: persist successful attributed order
OrderService -> LegacyOrderIdResolver: resolve legacy order ID
OrderService -> OrderUuidResolver: resolve UUID order ID
OrderService -> OrdersApiService: fetch customer status (HTTPS -> continuumOrdersService)
OrderService -> MDSHttpAdapter: fetch deal metadata (HTTPS -> continuumMarketingDealService)
OrderService -> continuumAflRtaMySql: INSERT attributed order (JDBC)
MBusOrderRegistration -> messageBus: publish attributed order (MBus/JMS)
RtaPollingConsumer -> janus-tier2 (Kafka): commit offset
```

## Related

- Architecture dynamic view: `dynamic-afl-rta-order-aflRta_clickAttribution`
- Related flows: [Click Attribution Flow](click-attribution-flow.md) — produces the click records consumed in step 4 of this flow
