---
service: "watson-realtime"
title: "Realtime KV Write"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "realtime-kv-write"
flow_type: event-driven
trigger: "Janus event arrives on janus-tier2_snc1 Kafka topic"
participants:
  - "kafkaCluster_9f3c"
  - "continuumRealtimeKvService"
  - "janusMetadataService_4d1e"
  - "raasRedis_3a1f"
architecture_ref: "components-realtime-kv-components"
---

# Realtime KV Write

## Summary

The Realtime KV Write flow processes incoming Janus tier2 events and persists per-user and per-deal key/value feature data to Redis. `continuumRealtimeKvService` runs a Kafka Streams topology that consumes each event, resolves its field schema from Janus Metadata Service (using a Caffeine cache to avoid redundant HTTP calls), extracts the relevant KV pairs, and writes them to `raasRedis_3a1f`. This data is subsequently read by watson-api to power low-latency ranking feature lookups.

## Trigger

- **Type**: event
- **Source**: `janus-tier2_snc1` Kafka topic (events published by Conveyor Cloud)
- **Frequency**: Per event — continuous streaming, rate driven by upstream event volume

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka Cluster | Source of Janus tier2 events | `kafkaCluster_9f3c` |
| Realtime KV Stream Processor | Consumes, transforms, and writes KV data | `continuumRealtimeKvService` |
| Janus Metadata Service | Provides event field schema and mapping definitions | `janusMetadataService_4d1e` |
| Redis (RaaS) | Target store for realtime KV pairs | `raasRedis_3a1f` |

## Steps

1. **Consume event**: `continuumRealtimeKvService` polls `janus-tier2_snc1` via its Kafka Streams consumer group.
   - From: `kafkaCluster_9f3c`
   - To: `continuumRealtimeKvService`
   - Protocol: Kafka

2. **Resolve event schema**: The processor checks the Caffeine in-process cache for the event type's schema. On a cache miss, it fetches field mappings from Janus Metadata Service.
   - From: `continuumRealtimeKvService`
   - To: `janusMetadataService_4d1e`
   - Protocol: HTTP (cache miss only)

3. **Extract KV pairs**: Using the resolved schema, the processor applies janus-thin-mapper and Avro deserialization to extract user/deal identifiers and feature values from the event payload.
   - From: `continuumRealtimeKvService`
   - To: `continuumRealtimeKvService` (internal transformation)
   - Protocol: direct

4. **Write to Redis**: The processor writes the extracted KV pairs to `raasRedis_3a1f` using Jedis, keyed by user ID and/or deal ID.
   - From: `continuumRealtimeKvService`
   - To: `raasRedis_3a1f`
   - Protocol: Redis

5. **Commit offset**: Kafka Streams commits the consumer offset after successful write, advancing the stream position.
   - From: `continuumRealtimeKvService`
   - To: `kafkaCluster_9f3c`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kafka broker unavailable | Kafka Streams built-in retry with backoff | Processing pauses; resumes from last committed offset on reconnect |
| Schema fetch failure (Janus Metadata Service) | Caffeine cache serves stale schema if available | Processing continues with cached schema; new event types may fail |
| Redis write failure | Kafka Streams exception handler; processing error | Stream topology may halt or route to error handler; offset not committed |
| Avro deserialization error | Kafka Streams deserialization exception handler | Record may be skipped or routed to error handler depending on configuration |

## Sequence Diagram

```
kafkaCluster_9f3c        -> continuumRealtimeKvService: Deliver janus-tier2_snc1 event (Kafka poll)
continuumRealtimeKvService -> janusMetadataService_4d1e: Fetch schema for event type (HTTP, cache miss only)
janusMetadataService_4d1e  --> continuumRealtimeKvService: Return field mappings
continuumRealtimeKvService -> continuumRealtimeKvService: Deserialize Avro payload, apply janus-thin-mapper, extract KV pairs
continuumRealtimeKvService -> raasRedis_3a1f: SET key/value pairs (Jedis)
raasRedis_3a1f             --> continuumRealtimeKvService: OK
continuumRealtimeKvService -> kafkaCluster_9f3c: Commit offset
```

## Related

- Architecture component view: `components-realtime-kv-components`
- Related flows: [Analytics Aggregation](analytics-aggregation.md), [RVD View Aggregation](rvd-view-aggregation.md), [User Identities Enrich](user-identities-enrich.md), [Dealview Counts](dealview-counts.md)
