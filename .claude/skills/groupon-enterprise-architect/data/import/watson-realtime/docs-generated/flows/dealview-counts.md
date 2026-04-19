---
service: "watson-realtime"
title: "Dealview Counts"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "dealview-counts"
flow_type: event-driven
trigger: "Janus event arrives on janus-tier2_snc1 Kafka topic"
participants:
  - "kafkaCluster_9f3c"
  - "continuumDealviewService"
  - "janusMetadataService_4d1e"
  - "raasRedis_3a1f"
architecture_ref: "components-dealview-components"
---

# Dealview Counts

## Summary

The Dealview Counts flow processes Janus tier2 events to maintain running deal view counters in Redis. `continuumDealviewService` runs a Kafka Streams topology that consumes each event, resolves the event schema from Janus Metadata Service (using a Caffeine cache), extracts the deal identifier, and increments or writes the deal view count to `raasRedis_3a1f` via Jedis. watson-api reads these counters to surface deal popularity signals during ranking and display.

## Trigger

- **Type**: event
- **Source**: `janus-tier2_snc1` Kafka topic (events published by Conveyor Cloud)
- **Frequency**: Per event — continuous streaming

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka Cluster | Source of Janus tier2 events | `kafkaCluster_9f3c` |
| Dealview Stream Processor | Consumes events, resolves schema, and writes deal view counters | `continuumDealviewService` |
| Janus Metadata Service | Provides event field schema and mapping definitions | `janusMetadataService_4d1e` |
| Redis (RaaS) | Target store for deal view counters | `raasRedis_3a1f` |

## Steps

1. **Consume event**: `continuumDealviewService` polls `janus-tier2_snc1` via its Kafka Streams consumer group.
   - From: `kafkaCluster_9f3c`
   - To: `continuumDealviewService`
   - Protocol: Kafka

2. **Resolve event schema**: The processor checks the Caffeine cache for the event type's field mappings. On a cache miss, it calls Janus Metadata Service.
   - From: `continuumDealviewService`
   - To: `janusMetadataService_4d1e`
   - Protocol: HTTP (cache miss only)

3. **Extract deal view fields**: Using the resolved schema and janus-thin-mapper, the processor deserializes the Avro payload and extracts the deal identifier and view signal data.
   - From: `continuumDealviewService`
   - To: `continuumDealviewService` (internal transformation)
   - Protocol: direct

4. **Write deal view counter to Redis**: The processor writes (or atomically increments) the deal view counter in `raasRedis_3a1f` using Jedis, keyed by deal ID.
   - From: `continuumDealviewService`
   - To: `raasRedis_3a1f`
   - Protocol: Redis

5. **Commit offset**: Kafka Streams commits the consumer offset after successful write.
   - From: `continuumDealviewService`
   - To: `kafkaCluster_9f3c`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kafka broker unavailable | Kafka Streams built-in retry with backoff | Processing pauses; resumes from last committed offset |
| Schema fetch failure (Janus Metadata Service) | Caffeine cache serves stale schema if available | Processing continues with cached schema; new event types may fail |
| Redis write failure | Kafka Streams exception handler | Stream topology may halt; offset not committed; record will be reprocessed |
| Avro deserialization error | Kafka Streams deserialization exception handler | Record skipped or routed to error handler |

## Sequence Diagram

```
kafkaCluster_9f3c   -> continuumDealviewService: Deliver janus-tier2_snc1 event (Kafka poll)
continuumDealviewService -> janusMetadataService_4d1e: Fetch schema for event type (HTTP, cache miss only)
janusMetadataService_4d1e --> continuumDealviewService: Return field mappings
continuumDealviewService -> continuumDealviewService: Deserialize Avro payload, extract deal ID and view fields
continuumDealviewService -> raasRedis_3a1f: INCR/SET deal view counter (Jedis)
raasRedis_3a1f       --> continuumDealviewService: OK
continuumDealviewService -> kafkaCluster_9f3c: Commit offset
```

## Related

- Architecture component view: `components-dealview-components`
- Related flows: [Realtime KV Write](realtime-kv-write.md), [RVD View Aggregation](rvd-view-aggregation.md), [Analytics Aggregation](analytics-aggregation.md)
