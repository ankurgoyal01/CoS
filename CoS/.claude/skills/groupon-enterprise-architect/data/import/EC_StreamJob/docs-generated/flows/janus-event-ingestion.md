---
service: "EC_StreamJob"
title: "Janus Event Ingestion and Filtering"
generated: "2026-03-03"
type: flow
flow_name: "janus-event-ingestion"
flow_type: event-driven
trigger: "New Avro-encoded message arrives on the janus-tier2 or janus-tier2_snc1 Kafka topic"
participants:
  - "kafkaTopicJanusTier2"
  - "janusApi"
  - "continuumEcStreamJob"
architecture_ref: "dynamic-TDMUpdateFlow"
---

# Janus Event Ingestion and Filtering

## Summary

This flow covers the first half of each 20-second Spark micro-batch: reading raw Avro-encoded Janus behavioral event bytes from Kafka, decoding them into JSON objects using the Janus metadata API, applying type and country filters, and building the deduplicated event queue ready for TDM posting. The Spark `foreachRDD` / `foreachPartition` loop drives this flow independently per partition.

## Trigger

- **Type**: event
- **Source**: New Avro message published to `janus-tier2` (NA) or `janus-tier2_snc1` (EMEA) Kafka topic by Janus behavioral event producers
- **Frequency**: Continuous; batched in 20-second windows (`BATCH_INTERVAL = 20`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka topic (`janus-tier2` / `janus-tier2_snc1`) | Source of raw Avro event bytes | `kafkaTopicJanusTier2` |
| Janus metadata API | Provides Avro schema for decoding | `janusApi` |
| EC Stream Job (`RealTimeJob`) | Consumes, decodes, filters, and deduplicates events | `continuumEcStreamJob` |

## Steps

1. **Consume Kafka partition batch**: Spark Streaming reads a 20-second batch of raw `Array[Byte]` messages from Kafka using the direct consumer API.
   - From: `kafkaTopicJanusTier2`
   - To: `continuumEcStreamJob`
   - Protocol: Kafka direct (0.8), consumer group `EC_StreamJobKafKaNAGroup` or `EC_StreamJobKafKaEMEAGroup`

2. **Decode Avro to JSON**: For each message in the partition, calls `AvroUtil.transform(bytes, janusURL)` which contacts the Janus metadata API to resolve the Avro schema and returns a JSON string.
   - From: `continuumEcStreamJob`
   - To: `janusApi`
   - Protocol: HTTP (GET schema metadata)

3. **Parse JSON object**: Wraps the decoded JSON string in a `org.json.JSONObject` for field access.
   - Internal to `continuumEcStreamJob`

4. **Filter by event type**: Retains only events where `event` equals `dealview` or `dealpurchase` (case-insensitive). Events of any other type are discarded.
   - Internal to `continuumEcStreamJob`
   - Predicate: `isPurchaseOrDealView()`

5. **Filter for required fields**: Verifies all of these fields are non-null: `country`, `consumerId`, `bcookie`, `dealUUID`, `eventTime`, `rawEvent`, `platform`. Events missing any field are discarded.
   - Internal to `continuumEcStreamJob`
   - Predicate: `isPurchaseOrDealView()`

6. **Filter by country (colo-specific)**: Checks `country` field against the colo whitelist.
   - NA colo: retains only `US`
   - EMEA colo: retains `UK`, `IT`, `FR`, `DE`, `ES`, `NL`, `PL`, `AE`, `BE`, `IE`, `NZ`, `AU`, `JP`
   - Predicate: `isValidCountry(event, colo)`

7. **Construct enriched payload**: Builds a `play.api.libs.json.JsObject` containing these fields extracted from the raw Janus event: `rawEvent`, `event`, `eventTime`, `country`, `dealUUID`, `bcookie`, `consumerId`, `platform` (from `clientPlatform`), `searchParameter`, `searchString`, `extraInfo`, `appVersion`, `dealStatus`, `brand`, `locale`, `dealRating`.
   - Internal to `continuumEcStreamJob`

8. **Deduplicate within partition**: Computes a composite string key from `event + country + bcookie + dealUUID + consumerId + platform + brand`. If the key already exists in the partition's `HashSet`, the event is dropped. Otherwise, the payload is added to the output `ListBuffer` queue and the key is recorded.
   - Internal to `continuumEcStreamJob`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Avro decode failure (Janus API unreachable or schema mismatch) | Exception propagates from `AvroUtil.transform()`; no try/catch wrapping the decode step | Partition batch may fail or affected events are skipped; job continues to next batch |
| Missing required event field (null) | `isPurchaseOrDealView()` returns false | Event silently discarded |
| Event type not dealview/dealpurchase | `isPurchaseOrDealView()` returns false | Event silently discarded |
| Country not in whitelist for colo | `isValidCountry()` returns false | Event silently discarded |
| Duplicate event within partition | Key already present in `HashSet` | Duplicate payload silently dropped |

## Sequence Diagram

```
Kafka(janus-tier2)   -> RealTimeJob: Deliver batch of raw Avro bytes (20s window)
RealTimeJob          -> JanusAPI:    HTTP GET schema metadata for Avro decoding
JanusAPI             --> RealTimeJob: Return Avro schema
RealTimeJob          -> RealTimeJob: Decode Avro -> JSONObject
RealTimeJob          -> RealTimeJob: isPurchaseOrDealView() — filter event type + required fields
RealTimeJob          -> RealTimeJob: isValidCountry() — filter by colo
RealTimeJob          -> RealTimeJob: Build JsObject payload
RealTimeJob          -> RealTimeJob: HashSet dedup — add to ListBuffer queue or discard
```

## Related

- Architecture dynamic view: `dynamic-TDMUpdateFlow`
- Related flows: [TDM User Data Update](tdm-user-data-update.md), [Spark Job Startup and Colo Selection](spark-job-startup.md)
