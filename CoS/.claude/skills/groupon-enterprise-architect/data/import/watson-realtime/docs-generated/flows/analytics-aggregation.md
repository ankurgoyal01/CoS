---
service: "watson-realtime"
title: "Analytics Aggregation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "analytics-aggregation"
flow_type: event-driven
trigger: "Janus event arrives on janus-tier2_snc1 or janus-impression_snc1 Kafka topic"
participants:
  - "kafkaCluster_9f3c"
  - "continuumAnalyticsKsService"
  - "cassandraKeyspaces_5c9a"
architecture_ref: "components-analytics-ks-components"
---

# Analytics Aggregation

## Summary

The Analytics Aggregation flow processes Janus impression and tier2 events and writes aggregated analytics counters to Cassandra/Keyspaces. `continuumAnalyticsKsService` runs a Kafka Streams topology that consumes events from both topics, applies aggregation logic (counting impressions and tier2 events by deal, user, and time bucket), and durably writes counter increments to `cassandraKeyspaces_5c9a` via the DataStax driver with AWS SigV4 authentication. The resulting counters are read by watson-api for analytics and ranking feature computation.

## Trigger

- **Type**: event
- **Source**: `janus-tier2_snc1` and `janus-impression_snc1` Kafka topics (events published by Conveyor Cloud)
- **Frequency**: Per event — continuous streaming across both topics

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka Cluster | Source of Janus impression and tier2 events | `kafkaCluster_9f3c` |
| Analytics KS Stream Processor | Consumes, aggregates, and writes counters | `continuumAnalyticsKsService` |
| Cassandra / Amazon Keyspaces | Target store for analytics counter data | `cassandraKeyspaces_5c9a` |

## Steps

1. **Consume event**: `continuumAnalyticsKsService` polls `janus-tier2_snc1` and `janus-impression_snc1` via its Kafka Streams consumer group(s).
   - From: `kafkaCluster_9f3c`
   - To: `continuumAnalyticsKsService`
   - Protocol: Kafka

2. **Deserialize payload**: The processor deserializes the Avro-encoded Janus event payload to extract the event type, deal ID, user ID, and timestamp.
   - From: `continuumAnalyticsKsService`
   - To: `continuumAnalyticsKsService` (internal transformation)
   - Protocol: direct

3. **Aggregate counter**: The Kafka Streams topology aggregates event counts by deal/user/event-type/time-bucket using a Kafka Streams state store or direct computation.
   - From: `continuumAnalyticsKsService`
   - To: `continuumAnalyticsKsService` (internal state)
   - Protocol: direct

4. **Write counter to Keyspaces**: The processor writes the counter increment to `cassandraKeyspaces_5c9a` using the DataStax Cassandra driver, with each request signed using AWS SigV4 via aws-sigv4 3.0.3.
   - From: `continuumAnalyticsKsService`
   - To: `cassandraKeyspaces_5c9a`
   - Protocol: Cassandra (with AWS SigV4 auth)

5. **Commit offset**: Kafka Streams commits the consumer offset after successful write.
   - From: `continuumAnalyticsKsService`
   - To: `kafkaCluster_9f3c`
   - Protocol: Kafka

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kafka broker unavailable | Kafka Streams built-in retry with backoff | Processing pauses; resumes from last committed offset on reconnect |
| AWS SigV4 credential expiry | Authentication failure on Cassandra write | Write fails; stream processing error; requires credential rotation and worker restart |
| Cassandra write failure | Kafka Streams exception handler | Stream topology may halt or route to error handler; offset not committed |
| Avro deserialization error | Kafka Streams deserialization exception handler | Record may be skipped or routed to error handler |

## Sequence Diagram

```
kafkaCluster_9f3c         -> continuumAnalyticsKsService: Deliver janus-impression_snc1 event (Kafka poll)
kafkaCluster_9f3c         -> continuumAnalyticsKsService: Deliver janus-tier2_snc1 event (Kafka poll)
continuumAnalyticsKsService -> continuumAnalyticsKsService: Deserialize Avro payload, extract deal/user/time fields
continuumAnalyticsKsService -> continuumAnalyticsKsService: Aggregate counter (Kafka Streams state)
continuumAnalyticsKsService -> cassandraKeyspaces_5c9a: Write counter increment (Cassandra driver + SigV4)
cassandraKeyspaces_5c9a    --> continuumAnalyticsKsService: OK
continuumAnalyticsKsService -> kafkaCluster_9f3c: Commit offset
```

## Related

- Architecture component view: `components-analytics-ks-components`
- Related flows: [KS Table Trim](ks-table-trim.md), [Realtime KV Write](realtime-kv-write.md)
