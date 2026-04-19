---
service: "watson-realtime"
title: "RVD View Aggregation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "rvd-view-aggregation"
flow_type: event-driven
trigger: "Janus event arrives on janus-tier2_snc1 Kafka topic"
participants:
  - "kafkaCluster_9f3c"
  - "continuumRvdService"
  - "janusMetadataService_4d1e"
  - "raasRedis_3a1f"
architecture_ref: "components-rvd-components"
---

# RVD View Aggregation

## Summary

The RVD View Aggregation flow processes Janus tier2 events to build realtime view data (RVD) aggregations per user and deal, writing results to Redis. `continuumRvdService` runs a Kafka Streams topology that consumes each event, resolves its schema from Janus Metadata Service (using a Caffeine cache), extracts view-related signals, aggregates them within the stream topology, and writes the resulting RVD records to `raasRedis_3a1f` using Jedis. watson-api reads these aggregations to support realtime ranking features.

## Trigger

- **Type**: event
- **Source**: `janus-tier2_snc1` Kafka topic (events published by Conveyor Cloud)
- **Frequency**: Per event — continuous streaming

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka Cluster | Source of Janus tier2 events | `kafkaCluster_9f3c` |
| RVD Stream Processor | Consumes, aggregates view data, and writes to Redis | `continuumRvdService` |
| Janus Metadata Service | Provides event field schema and mapping definitions | `janusMetadataService_4d1e` |
| Redis (RaaS) | Target store for RVD aggregation records | `raasRedis_3a1f` |

## Steps

1. **Consume event**: `continuumRvdService` polls `janus-tier2_snc1` via its Kafka Streams consumer group.
   - From: `kafkaCluster_9f3c`
   - To: `continuumRvdService`
   - Protocol: Kafka

2. **Resolve event schema**: The processor checks the Caffeine cache for the event type's field mappings. On a cache miss, it calls Janus Metadata Service.
   - From: `continuumRvdService`
   - To: `janusMetadataService_4d1e`
   - Protocol: HTTP (cache miss only)

3. **Extract view signals**: Using the resolved schema and janus-thin-mapper, the processor deserializes the Avro payload and extracts view-related fields (user ID, deal ID, view signal data).
   - From: `continuumRvdService`
   - To: `continuumRvdService` (internal transformation)
   - Protocol: direct

4. **Aggregate realtime view data**: The Kafka Streams topology aggregates the view signals (e.g., rolling counts or weighted scores) per user/deal dimension.
   - From: `continuumRvdService`
   - To: `continuumRvdService` (internal state)
   - Protocol: direct

5. **Write RVD to Redis**: The processor writes the aggregated RVD records to `raasRedis_3a1f` using Jedis, keyed by user ID and deal ID.
   - From: `continuumRvdService`
   - To: `raasRedis_3a1f`
   - Protocol: Redis

6. **Commit offset**: Kafka Streams commits the consumer offset after successful write.
   - From: `continuumRvdService`
   - To: `kafkaCluster_9f3c`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kafka broker unavailable | Kafka Streams built-in retry with backoff | Processing pauses; resumes from last committed offset |
| Schema fetch failure (Janus Metadata Service) | Caffeine cache serves stale schema if available | Processing continues with cached data; new event types may fail |
| Redis write failure | Kafka Streams exception handler | Stream topology may halt; offset not committed |
| Avro deserialization error | Kafka Streams deserialization exception handler | Record skipped or routed to error handler |

## Sequence Diagram

```
kafkaCluster_9f3c  -> continuumRvdService: Deliver janus-tier2_snc1 event (Kafka poll)
continuumRvdService -> janusMetadataService_4d1e: Fetch schema for event type (HTTP, cache miss only)
janusMetadataService_4d1e --> continuumRvdService: Return field mappings
continuumRvdService -> continuumRvdService: Deserialize Avro payload, extract view signals
continuumRvdService -> continuumRvdService: Aggregate RVD per user/deal (Kafka Streams state)
continuumRvdService -> raasRedis_3a1f: Write RVD aggregation (Jedis)
raasRedis_3a1f      --> continuumRvdService: OK
continuumRvdService -> kafkaCluster_9f3c: Commit offset
```

## Related

- Architecture component view: `components-rvd-components`
- Related flows: [Realtime KV Write](realtime-kv-write.md), [Dealview Counts](dealview-counts.md), [User Identities Enrich](user-identities-enrich.md)
