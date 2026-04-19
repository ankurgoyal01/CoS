---
service: "watson-realtime"
title: "Cookie Identity Map"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "cookie-identity-map"
flow_type: event-driven
trigger: "Janus event arrives on janus-tier2_snc1 Kafka topic"
participants:
  - "kafkaCluster_9f3c"
  - "continuumCookiesService"
  - "janusMetadataService_4d1e"
  - "postgresCookiesDb_2f7a"
architecture_ref: "components-cookies-components"
---

# Cookie Identity Map

## Summary

The Cookie Identity Map flow processes Janus tier2 events to build and maintain a mapping between consumer bcookie identifiers and resolved user identities in PostgreSQL. `continuumCookiesService` consumes each event, resolves the event schema from Janus Metadata Service (using a Caffeine in-process cache), extracts the bcookie and associated user identity fields, and upserts the mapping record into `postgresCookiesDb_2f7a` via JDBI3. These mappings allow downstream systems to resolve anonymous cookie-based identifiers to known user profiles.

## Trigger

- **Type**: event
- **Source**: `janus-tier2_snc1` Kafka topic (events published by Conveyor Cloud)
- **Frequency**: Per event — continuous streaming

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka Cluster | Source of Janus tier2 events | `kafkaCluster_9f3c` |
| Cookies Stream Processor | Consumes events, resolves schema, and writes cookie mappings | `continuumCookiesService` |
| Janus Metadata Service | Provides event field schema and mapping definitions | `janusMetadataService_4d1e` |
| PostgreSQL (Cookies DB) | Target store for bcookie-to-identity mappings | `postgresCookiesDb_2f7a` |

## Steps

1. **Consume event**: `continuumCookiesService` polls `janus-tier2_snc1` via its Kafka Streams consumer group.
   - From: `kafkaCluster_9f3c`
   - To: `continuumCookiesService`
   - Protocol: Kafka

2. **Resolve event schema**: The processor checks the Caffeine cache for the event type's field mappings. On a cache miss, it calls Janus Metadata Service to fetch the schema.
   - From: `continuumCookiesService`
   - To: `janusMetadataService_4d1e`
   - Protocol: HTTP (cache miss only)

3. **Extract cookie and identity fields**: Using the resolved schema and janus-thin-mapper, the processor deserializes the Avro payload and extracts the bcookie value and associated user identity attributes.
   - From: `continuumCookiesService`
   - To: `continuumCookiesService` (internal transformation)
   - Protocol: direct

4. **Upsert mapping to PostgreSQL**: The processor uses JDBI3 to upsert the bcookie-to-identity mapping record into `postgresCookiesDb_2f7a`.
   - From: `continuumCookiesService`
   - To: `postgresCookiesDb_2f7a`
   - Protocol: PostgreSQL (JDBC)

5. **Commit offset**: Kafka Streams commits the consumer offset after successful write.
   - From: `continuumCookiesService`
   - To: `kafkaCluster_9f3c`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kafka broker unavailable | Kafka Streams built-in retry | Processing pauses; resumes from last committed offset on reconnect |
| Schema fetch failure (Janus Metadata Service) | Caffeine cache serves stale schema if available | Processing continues with cached schema; new event types may fail |
| PostgreSQL write failure | Kafka Streams exception handler | Stream topology may halt; offset not committed; record will be reprocessed |
| Avro deserialization error | Kafka Streams deserialization exception handler | Record may be skipped or routed to error handler |
| PostgreSQL connection pool exhausted | JDBI3/JDBC connection error | Write fails; stream processing error logged |

## Sequence Diagram

```
kafkaCluster_9f3c      -> continuumCookiesService: Deliver janus-tier2_snc1 event (Kafka poll)
continuumCookiesService -> janusMetadataService_4d1e: Fetch schema for event type (HTTP, cache miss only)
janusMetadataService_4d1e --> continuumCookiesService: Return field mappings
continuumCookiesService -> continuumCookiesService: Deserialize Avro payload, apply janus-thin-mapper, extract bcookie + identity fields
continuumCookiesService -> postgresCookiesDb_2f7a: Upsert cookie mapping (JDBI3)
postgresCookiesDb_2f7a  --> continuumCookiesService: OK
continuumCookiesService -> kafkaCluster_9f3c: Commit offset
```

## Related

- Architecture component view: `components-cookies-components`
- Related flows: [User Identities Enrich](user-identities-enrich.md), [Realtime KV Write](realtime-kv-write.md)
