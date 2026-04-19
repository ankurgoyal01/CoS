---
service: "watson-realtime"
title: "User Identities Enrich"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "user-identities-enrich"
flow_type: event-driven
trigger: "Janus event arrives on janus-tier2_snc1 Kafka topic"
participants:
  - "kafkaCluster_9f3c"
  - "continuumUserIdentitiesService"
  - "janusMetadataService_4d1e"
  - "raasRedis_3a1f"
architecture_ref: "components-user-identities-components"
---

# User Identities Enrich

## Summary

The User Identities Enrich flow processes Janus tier2 events to maintain enriched user identity records in Redis. `continuumUserIdentitiesService` runs a Kafka Streams topology that consumes each event, resolves the event schema from Janus Metadata Service (using a Caffeine cache), extracts and enriches user identity attributes (such as user IDs, device identifiers, and session data), and writes the resulting identity records to `raasRedis_3a1f` via Jedis. These records are read by watson-api to associate behavioural signals with resolved user profiles during ranking.

## Trigger

- **Type**: event
- **Source**: `janus-tier2_snc1` Kafka topic (events published by Conveyor Cloud)
- **Frequency**: Per event — continuous streaming

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka Cluster | Source of Janus tier2 events | `kafkaCluster_9f3c` |
| User Identities Stream Processor | Consumes events, enriches user identity records, and writes to Redis | `continuumUserIdentitiesService` |
| Janus Metadata Service | Provides event field schema and mapping definitions | `janusMetadataService_4d1e` |
| Redis (RaaS) | Target store for enriched user identity records | `raasRedis_3a1f` |

## Steps

1. **Consume event**: `continuumUserIdentitiesService` polls `janus-tier2_snc1` via its Kafka Streams consumer group.
   - From: `kafkaCluster_9f3c`
   - To: `continuumUserIdentitiesService`
   - Protocol: Kafka

2. **Resolve event schema**: The processor checks the Caffeine cache for the event type's field mappings. On a cache miss, it fetches the schema from Janus Metadata Service.
   - From: `continuumUserIdentitiesService`
   - To: `janusMetadataService_4d1e`
   - Protocol: HTTP (cache miss only)

3. **Extract identity fields**: Using the resolved schema and janus-thin-mapper, the processor deserializes the Avro payload and extracts user identity attributes (user ID, device ID, session identifiers, etc.).
   - From: `continuumUserIdentitiesService`
   - To: `continuumUserIdentitiesService` (internal transformation)
   - Protocol: direct

4. **Enrich identity record**: The processor applies enrichment logic to the extracted fields, building a consolidated user identity record.
   - From: `continuumUserIdentitiesService`
   - To: `continuumUserIdentitiesService` (internal computation)
   - Protocol: direct

5. **Write identity to Redis**: The processor writes the enriched user identity record to `raasRedis_3a1f` using Jedis, keyed by user ID.
   - From: `continuumUserIdentitiesService`
   - To: `raasRedis_3a1f`
   - Protocol: Redis

6. **Commit offset**: Kafka Streams commits the consumer offset after successful write.
   - From: `continuumUserIdentitiesService`
   - To: `kafkaCluster_9f3c`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kafka broker unavailable | Kafka Streams built-in retry with backoff | Processing pauses; resumes from last committed offset |
| Schema fetch failure (Janus Metadata Service) | Caffeine cache serves stale schema if available | Processing continues with cached schema; new event types may fail |
| Redis write failure | Kafka Streams exception handler | Stream topology may halt; offset not committed |
| Avro deserialization error | Kafka Streams deserialization exception handler | Record skipped or routed to error handler |

## Sequence Diagram

```
kafkaCluster_9f3c          -> continuumUserIdentitiesService: Deliver janus-tier2_snc1 event (Kafka poll)
continuumUserIdentitiesService -> janusMetadataService_4d1e: Fetch schema for event type (HTTP, cache miss only)
janusMetadataService_4d1e   --> continuumUserIdentitiesService: Return field mappings
continuumUserIdentitiesService -> continuumUserIdentitiesService: Deserialize Avro payload, extract identity fields
continuumUserIdentitiesService -> continuumUserIdentitiesService: Apply enrichment logic, build identity record
continuumUserIdentitiesService -> raasRedis_3a1f: Write enriched identity record (Jedis)
raasRedis_3a1f               --> continuumUserIdentitiesService: OK
continuumUserIdentitiesService -> kafkaCluster_9f3c: Commit offset
```

## Related

- Architecture component view: `components-user-identities-components`
- Related flows: [Cookie Identity Map](cookie-identity-map.md), [Realtime KV Write](realtime-kv-write.md), [RVD View Aggregation](rvd-view-aggregation.md)
