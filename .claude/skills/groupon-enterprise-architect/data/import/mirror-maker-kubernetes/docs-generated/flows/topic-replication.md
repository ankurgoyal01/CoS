---
service: "mirror-maker-kubernetes"
title: "Topic Replication"
generated: "2026-03-03"
type: flow
flow_name: "topic-replication"
flow_type: event-driven
trigger: "Records available on whitelisted source topics"
participants:
  - "continuumMirrorMakerService"
  - "continuumKafkaBroker"
  - "metricsStack"
  - "loggingStack"
architecture_ref: "dynamic-mirror-maker-replication-flow"
---

# Topic Replication

## Summary

The core continuous replication loop operates after the MirrorMaker pod has completed startup. The MirrorMaker consumer polls records from the whitelisted source topics, optionally transforms the destination topic name (via prefix or Janus rename), and publishes records to the destination cluster using the configured producer. This flow runs indefinitely for the pod lifetime and is the primary business function of the service.

## Trigger

- **Type**: Event (records available on source Kafka topic partitions)
- **Source**: Any Groupon service producing to whitelisted source topics (e.g., Janus notification service producing to `janus-all_snc1`)
- **Frequency**: Continuous; rate determined by source topic throughput

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MirrorMaker Service | Orchestrates consume-produce loop across all assigned partitions | `continuumMirrorMakerService` |
| Source Kafka Cluster | Supplies records from whitelisted topics to the MirrorMaker consumer | `continuumKafkaBroker` |
| Destination Kafka Cluster | Receives replicated records on prefixed/renamed destination topics | `continuumKafkaBroker` |
| Metrics Stack | Receives Jolokia-scraped consumer lag, throughput, and drop count metrics | `metricsStack` |
| Logging Stack | Receives MirrorMaker runtime log stream | `loggingStack` |

## Steps

1. **Poll source topic partitions**: The MirrorMaker consumer polls the source broker for records on each assigned partition of the whitelisted topics (per `WHITELIST` env var). The poll batch size and timeout are governed by the consumer properties generated at startup.
   - From: `continuumMirrorMakerService`
   - To: `continuumKafkaBroker` (source)
   - Protocol: Kafka consumer protocol (TCP, port 9093 mTLS or 9094)

2. **Apply topic name transform**: If `USE_DESTINATION_TOPIC_PREFIX=true`, each record's destination topic is set to `<DESTINATION_TOPIC_PREFIX>.<source-topic>` (e.g., `k8s.janus-all_snc1`). If `IS_JANUS_FORWARDER=true` and `DESTINATION_TOPIC_NAME` is set, all records are routed to the single renamed topic. Without these flags, the source topic name is used as-is on the destination.
   - From: `mirrorMaker_runtimeLauncher` (in-process message handler)
   - To: Producer buffer
   - Protocol: In-process

3. **Batch records for production**: Records accumulate in the producer buffer up to `BATCH_SIZE` bytes or until `LINGER_MS` milliseconds elapse, then are flushed as a compressed batch (Snappy codec).
   - From: `continuumMirrorMakerService` (producer buffer)
   - To: `continuumKafkaBroker` (destination)
   - Protocol: Kafka producer protocol (TCP, port 9093 mTLS or 9094)

4. **Publish to destination cluster**: The batched records are sent to the destination broker. The producer waits for `ACKS=1` acknowledgement (leader acknowledgement). Successfully produced records are committed.
   - From: `continuumMirrorMakerService`
   - To: `continuumKafkaBroker` (destination)
   - Protocol: Kafka producer protocol

5. **Commit source offsets**: After successful production, the consumer commits offsets for the consumed partitions to the source broker, advancing the consumer group position. This ensures at-least-once delivery semantics.
   - From: `continuumMirrorMakerService`
   - To: `continuumKafkaBroker` (source)
   - Protocol: Kafka consumer offset commit

6. **Emit metrics**: Every 60 seconds, the Telegraf sidecar scrapes the Jolokia endpoint (`http://localhost:8778/jolokia`) for JMX metrics (consumer lag, throughput, error rates, drop count) and forwards them to InfluxDB.
   - From: `continuumMirrorMakerService` (Jolokia/JMX)
   - To: `metricsStack`
   - Protocol: HTTP (Jolokia2) → InfluxDB line protocol

7. **Emit logs**: The MirrorMaker process writes operational log output to `/var/log/mirror-maker/mirror-maker.log`. The Filebeat sidecar tails this file and ships entries to the central logging stack.
   - From: `continuumMirrorMakerService`
   - To: `loggingStack`
   - Protocol: Filebeat

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Destination broker unavailable | Producer retries with backoff; records accumulate in buffer | Buffer fills up; records exceeding buffer are dropped; `MirrorMaker-numDroppedMessages` increments |
| Source broker unavailable | Consumer pauses polling; heartbeat continues | Consumer lag accumulates; no records are dropped from source (they remain on source cluster) |
| Record exceeding `MAX_REQUEST_SIZE` | Producer rejects with exception | Record is dropped; `record-error-rate` metric increments |
| Consumer group rebalance | Kafka triggers rebalance; partitions are reassigned | Brief pause in consumption; no data loss; offsets committed before rebalance |

## Sequence Diagram

```
MirrorMakerService -> KafkaBroker(source): Poll records from WHITELIST topics
KafkaBroker(source) --> MirrorMakerService: Return record batch
MirrorMakerService -> MirrorMakerService: Apply topic prefix/rename transform
MirrorMakerService -> KafkaBroker(destination): Produce batched records (Snappy, ACKS=1)
KafkaBroker(destination) --> MirrorMakerService: Acknowledge (ACKS=1)
MirrorMakerService -> KafkaBroker(source): Commit consumer offsets
Telegraf(sidecar) -> MirrorMakerService: Scrape Jolokia metrics (port 8778)
Telegraf(sidecar) -> MetricsStack: Forward metrics to InfluxDB
Filebeat(sidecar) -> LoggingStack: Ship /var/log/mirror-maker/mirror-maker.log
```

## Related

- Architecture dynamic view: `dynamic-mirror-maker-replication-flow`
- Related flows: [Startup and Initialization](startup-initialization.md), [Janus Topic Forwarding](janus-topic-forwarding.md), [Cross-Cloud Replication](cross-cloud-replication.md)
