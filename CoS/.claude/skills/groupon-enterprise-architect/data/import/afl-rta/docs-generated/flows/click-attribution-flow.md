---
service: "afl-rta"
title: "Click Attribution Flow"
generated: "2026-03-03"
type: flow
flow_name: "click-attribution-flow"
flow_type: event-driven
trigger: "externalReferrer event consumed from Kafka janus-tier2 topic"
participants:
  - "continuumJanusTier2Topic"
  - "continuumAflRtaService"
  - "continuumAflRtaMySql"
architecture_ref: "dynamic-afl-rta-click-aflRta_clickAttribution"
---

# Click Attribution Flow

## Summary

When a user clicks on a Groupon link from an affiliate or marketing channel website, Janus processes the referrer event and produces an `externalReferrer` record on the `janus-tier2` Kafka topic. AFL RTA consumes this event, runs it through the click attribution strategy to identify the marketing channel and affiliate responsible for the click, and persists the attributed click record to MySQL. The stored click is later used as the correlation basis for the 7-day order attribution window.

## Trigger

- **Type**: event
- **Source**: `janus-tier2` Kafka topic (event type: `externalReferrer`); produced by the Janus data-engineering pipeline
- **Frequency**: Per-request (continuous; one record per qualifying user referrer event from any Groupon platform)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Janus Tier 2 Kafka Topic | Source of inbound `externalReferrer` events | `continuumJanusTier2Topic` |
| RtaPollingConsumer | Polls Kafka and forwards messages for processing | `continuumAflRtaService` |
| EventProcessor | Deserializes the Kafka record and routes it to the appropriate strategy | `continuumAflRtaService` |
| ClickAttributionStrategy | Executes click-level attribution logic, identifies channel and affiliate | `continuumAflRtaService` |
| ClicksService | Validates and persists the attributed click record | `continuumAflRtaService` |
| AFL RTA MySQL | Stores the attributed click for future order correlation | `continuumAflRtaMySql` |

## Steps

1. **Poll Kafka record**: `RtaPollingConsumer` polls a batch of records from the `janus-tier2` Kafka topic.
   - From: `continuumJanusTier2Topic`
   - To: `RtaPollingConsumer` (within `continuumAflRtaService`)
   - Protocol: Kafka (TLS, kafka-clients 2.7.0)

2. **Dispatch to EventProcessor**: The polled message payload is handed to `EventProcessor` for deserialization and routing.
   - From: `RtaPollingConsumer`
   - To: `EventProcessor`
   - Protocol: direct (in-process)

3. **Deserialize and route**: `EventProcessor` uses `janus-thin-mapper` to deserialize the Avro/JSON payload and identifies the event type as `externalReferrer`, routing to `ClickAttributionStrategy`.
   - From: `EventProcessor`
   - To: `ClickAttributionStrategy`
   - Protocol: direct (in-process)

4. **Perform click attribution**: `ClickAttributionStrategy` applies attribution rules — identifying the marketing channel (e.g., CJ, GPN, AFL) from the referrer URL and promo code, filtering events that do not meet attribution criteria.
   - From: `EventProcessor`
   - To: `ClickAttributionStrategy`
   - Protocol: direct (in-process)

5. **Register attributed click**: `ClickAttributionStrategy` calls `ClicksService` to persist the attributed click (including bcookie, channel, affiliate ID, click URL, promo code, and timestamp) to MySQL.
   - From: `ClickAttributionStrategy`
   - To: `ClicksService`
   - Protocol: direct (in-process)

6. **Write to MySQL**: `ClicksService` inserts the click record into the `continuumAflRtaMySql` clicks table via JDBC.
   - From: `ClicksService`
   - To: `continuumAflRtaMySql`
   - Protocol: JDBC

7. **Commit Kafka offset**: `RtaPollingConsumer` commits the offset for the processed record to Kafka, marking it as consumed.
   - From: `RtaPollingConsumer`
   - To: `continuumJanusTier2Topic`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Malformed click URL (`URISyntaxException`) | Exception is logged; event is skipped | Click is not stored; offset is still committed; Wavefront exception alert may fire |
| Event does not match attribution criteria | Filtered out by `ClickAttributionStrategy` | Event is skipped without storing; offset is committed |
| MySQL write failure | Exception propagates; offset is not committed | Consumer retries from the same offset on next poll cycle |
| Kafka connectivity loss | Consumer polling stalls; reconnection handled by kafka-clients | Processing resumes from last committed offset when connectivity is restored |

## Sequence Diagram

```
janus-tier2 (Kafka) -> RtaPollingConsumer: externalReferrer event record
RtaPollingConsumer -> EventProcessor: dispatch message payload
EventProcessor -> ClickAttributionStrategy: route externalReferrer event
ClickAttributionStrategy -> ClicksService: register attributed click
ClicksService -> continuumAflRtaMySql: INSERT click record (JDBC)
continuumAflRtaMySql --> ClicksService: write confirmed
RtaPollingConsumer -> janus-tier2 (Kafka): commit offset
```

## Related

- Architecture dynamic view: `dynamic-afl-rta-click-aflRta_clickAttribution`
- Related flows: [Order Attribution Flow](order-attribution-flow.md) — consumes click records stored by this flow
