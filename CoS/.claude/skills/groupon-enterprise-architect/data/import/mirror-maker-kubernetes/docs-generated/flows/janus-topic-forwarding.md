---
service: "mirror-maker-kubernetes"
title: "Janus Topic Forwarding"
generated: "2026-03-03"
type: flow
flow_name: "janus-topic-forwarding"
flow_type: event-driven
trigger: "Janus notification records available on whitelisted source topics"
participants:
  - "continuumMirrorMakerService"
  - "mirrorMaker_runtimeLauncher"
  - "continuumKafkaBroker"
architecture_ref: "dynamic-mirror-maker-replication-flow"
---

# Janus Topic Forwarding

## Summary

The Janus topic forwarding flow is a specialized variant of the standard topic replication flow, activated by setting `IS_JANUS_FORWARDER=true`. It handles Groupon's Janus notification event streams, which require special topic routing logic: either all records from multiple source topics are funneled into a single renamed destination topic (using `DESTINATION_TOPIC_NAME`), or source topics are prefixed with an environment label (using `DESTINATION_TOPIC_PREFIX`). This flow serves notification workers on MSK or GCP that cannot directly access the K8s-native Kafka cluster where Janus producers run.

## Trigger

- **Type**: Event (Janus notification records on source topics)
- **Source**: Janus notification service producing to topics such as `janus-all_snc1`, `janus-tier1`, `janus-tier2`, `janus-tier3`, `janus-cloud-all_snc1`, `janus-cloud-email_snc1`, `gcs-janus-replay`
- **Frequency**: Continuous; high-throughput (up to 40 replicas for the `janus-all-eu` forwarder)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MirrorMaker Runtime Launcher | Activates Janus message handler class; executes topic transform logic | `mirrorMaker_runtimeLauncher` |
| MirrorMaker Service (overall) | Consumer-producer coordinator | `continuumMirrorMakerService` |
| Source Kafka Cluster | Provides Janus topic records (K8s-native cluster, MSK, or GCP) | `continuumKafkaBroker` |
| Destination Kafka Cluster | Receives Janus records under transformed topic name (MSK, GCP, or K8s) | `continuumKafkaBroker` |

## Steps

1. **Consume Janus source topics**: The MirrorMaker consumer polls the source broker for records on the topics in the Janus `WHITELIST` (e.g., `janus-all_snc1|janus-tier1|janus-tier2|janus-tier3|janus-raw|janus-cloud-all_snc1|janus-cloud-email_snc1|gcs-janus-replay`).
   - From: `continuumMirrorMakerService`
   - To: `continuumKafkaBroker` (source)
   - Protocol: Kafka consumer protocol

2. **Apply Janus message handler transform**: The Janus forwarder message handler (activated via `IS_JANUS_FORWARDER=true`) intercepts each record. If `DESTINATION_TOPIC_NAME` is set (rename mode), all records are directed to that single topic regardless of source topic (example: `janus-all_snc1` → `janus-all-eu`). If `USE_DESTINATION_TOPIC_PREFIX=true`, each source topic is prefixed (example: `janus-all_snc1` → `k8s.janus-all_snc1`, `msk.janus-all_snc1`, or `gcp.janus-all_snc1` depending on `DESTINATION_TOPIC_PREFIX`).
   - From: `mirrorMaker_runtimeLauncher` (in-process message handler)
   - To: Producer buffer
   - Protocol: In-process

3. **Batch and compress for high throughput**: Records are buffered to `BATCH_SIZE=200000` bytes and flushed after `LINGER_MS=1000` ms, then Snappy-compressed. This batch configuration is tuned for Janus traffic volume.
   - From: `continuumMirrorMakerService`
   - To: `continuumKafkaBroker` (destination)
   - Protocol: Kafka producer protocol

4. **Publish to destination cluster under transformed topic**: Produces to the destination broker. For cross-region Janus forwarders (e.g., `janus-all-eu` mirror: `eu-west-1 MSK → us-west-2 MSK`), source and destination are on different MSK cluster endpoints. `AUTO_OFFSET_RESET=earliest` is used in the `janus-all-eu` forwarder to ensure no records are skipped after a pod restart.
   - From: `continuumMirrorMakerService`
   - To: `continuumKafkaBroker` (destination, cross-region)
   - Protocol: Kafka producer protocol (TCP port 9094)

5. **Commit source offsets**: Consumer offsets committed to source broker after successful produce, maintaining at-least-once delivery.
   - From: `continuumMirrorMakerService`
   - To: `continuumKafkaBroker` (source)
   - Protocol: Kafka offset commit

## Deployed Janus Forwarder Components (Production)

| Component | Source | Destination | Transform |
|-----------|--------|-------------|-----------|
| `k8s-msk-janus-mirrors` (eu-west-1) | K8s-native kafka (9093 mTLS) | MSK eu-west-1 (9094) | Prefix `k8s.` |
| `msk-k8s-janus-mirrors` (eu-west-1) | MSK eu-west-1 (9094) | K8s-native kafka (9093 mTLS) | Prefix `msk.` |
| `gcp-msk-janus-mirrors` (europe-west1) | K8s-native kafka (9093 mTLS) | MSK eu-west-1 (9094) | Prefix `gcp.` |
| `msk-gcp-janus-mirrors` (europe-west1) | MSK eu-west-1 (9094) | K8s-native kafka (9093 mTLS) | Prefix `msk.` |
| `gcp-msk-janus-mirrors` (us-central1) | K8s-native kafka (9093 mTLS) | MSK us-west-2 (9094) | Prefix `gcp.` |
| `janus-all-eu` (eu-west-1) | MSK eu-west-1 (9094) | MSK us-west-2 (9094) | Rename to `janus-all-eu` |
| `janus-all-forwarder` (eu-west-1) | K8s-native kafka | MSK eu-west-1 | Prefix forwarding |
| `janus-tier1/2/3-forwarder` (eu-west-1) | K8s-native kafka | MSK eu-west-1 | Tier-specific prefix |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Source Janus topic partition missing | MirrorMaker skips and logs | No records consumed for that partition |
| Destination topic not yet created on destination cluster | Producer fails with topic error | Records dropped; `record-error-rate` increments; topic must be pre-created |
| Pod restart mid-stream | Consumer group rejoins; `AUTO_OFFSET_RESET=latest` (default) or `earliest` (janus-all-eu) applies | With `latest`: in-flight records since last commit may be skipped; with `earliest`: replay from committed offset |

## Sequence Diagram

```
JanusService -> KafkaBroker(source): Produce to janus-all_snc1 (and other whitelist topics)
MirrorMakerService -> KafkaBroker(source): Poll janus-all_snc1, janus-tier1, janus-raw, etc.
KafkaBroker(source) --> MirrorMakerService: Return record batch
MirrorMakerService -> JanusMessageHandler: Apply IS_JANUS_FORWARDER transform
JanusMessageHandler --> MirrorMakerService: Renamed topic (e.g., k8s.janus-all_snc1 or janus-all-eu)
MirrorMakerService -> KafkaBroker(destination): Produce prefixed/renamed records (Snappy, LINGER=1000ms)
KafkaBroker(destination) --> MirrorMakerService: ACKS=1
MirrorMakerService -> KafkaBroker(source): Commit offsets
```

## Related

- Architecture dynamic view: `dynamic-mirror-maker-replication-flow`
- Related flows: [Topic Replication](topic-replication.md), [Cross-Cloud Replication](cross-cloud-replication.md)
