---
service: "janus-engine"
title: "Kafka Stream Curation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "kafka-stream-curation"
flow_type: event-driven
trigger: "Raw event arrives on a Kafka source topic"
participants:
  - "continuumJanusEngine"
  - "kafkaIngestionAdapter"
  - "curationProcessor"
  - "janusMetadataClientComponent"
  - "janusEngine_kafkaPublisher"
  - "janusEngine_healthAndMetrics"
architecture_ref: "components-janusEngineComponents"
---

# Kafka Stream Curation

## Summary

In `KAFKA` mode, Janus Engine uses a Kafka Streams 2.7.0 topology to consume raw domain events from configured Kafka source topics, apply curation rules and mapper transformations, and publish the resulting canonical events to the appropriate tiered Janus sink topics. This is the primary high-throughput processing mode for direct Kafka-to-Kafka pipelines.

## Trigger

- **Type**: event
- **Source**: Raw domain event arrives on a configured Kafka source topic
- **Frequency**: Continuous (per-message, high-volume)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Janus Engine (Kafka Streams) | Hosts the Kafka Streams topology; entry point | `continuumJanusEngine` |
| Kafka Streams Engine Adapter | Subscribes to Kafka source topics; drives stream topology | `kafkaIngestionAdapter` |
| Curator Processor | Normalizes and transforms source payload into canonical Janus event | `curationProcessor` |
| Janus Metadata Client | Supplies mapper definitions and routing rules | `janusMetadataClientComponent` |
| Kafka Publisher | Publishes canonical event envelope to the correct sink topic | `janusEngine_kafkaPublisher` |
| Health and Metrics | Emits Kafka Streams runtime metrics | `janusEngine_healthAndMetrics` |

## Steps

1. **Receive source event**: `kafkaIngestionAdapter` receives a raw event from a Kafka source topic via the Kafka Streams topology.
   - From: Kafka source topic
   - To: `kafkaIngestionAdapter`
   - Protocol: Kafka (kafka-streams 2.7.0)

2. **Fetch mapper metadata**: `curationProcessor` requests the mapper definition and curation rules for the event's source topic and event type.
   - From: `curationProcessor`
   - To: `janusMetadataClientComponent`
   - Protocol: direct (in-process cache lookup; HTTP fallback to Janus metadata service if cache miss)

3. **Apply curation and transform**: `curationProcessor` normalizes the raw payload against the mapper definition, resolves routing tier, and produces a canonical Janus event envelope.
   - From: `kafkaIngestionAdapter`
   - To: `curationProcessor`
   - Protocol: direct

4. **Publish canonical event**: `janusEngine_kafkaPublisher` writes the canonical event to the appropriate Janus sink topic (`janus-cloud-tier1`, `janus-cloud-tier2`, `janus-cloud-tier3`, `janus-cloud-impression`, or `janus-cloud-email`).
   - From: `curationProcessor` → `janusEngine_kafkaPublisher`
   - To: Kafka sink topic
   - Protocol: Kafka (kafka-clients 2.7.0)

5. **Emit metrics**: `kafkaIngestionAdapter` and `janusEngine_healthAndMetrics` emit processing counters and stream health indicators to `metricsStack`.
   - From: `kafkaIngestionAdapter`, `janusEngine_healthAndMetrics`
   - To: `metricsStack`
   - Protocol: SMA metrics

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Mapper not found for event type | `curationProcessor` cannot transform; event is skipped or routed to DLQ | Event lands in dead-letter queue for reprocessing via [DLQ Replay](dlq-replay.md) |
| Kafka publish failure | Kafka producer retries (at-least-once); Kafka Streams error handler activated | Event may be retried; persistent failure routes to DLQ or halts stream |
| Metadata service unreachable | `janusMetadataClientComponent` serves cached metadata | Processing continues with stale rules; stale-metadata alert should fire |
| Deserialization error | Kafka Streams deserialization error handler | Malformed record routed to DLQ or logged and skipped |

## Sequence Diagram

```
Kafka source topic   -> kafkaIngestionAdapter  : Delivers raw event
kafkaIngestionAdapter -> curationProcessor     : Passes raw payload for transformation
curationProcessor    -> janusMetadataClientComponent : Requests mapper/rules for (topic, event type)
janusMetadataClientComponent --> curationProcessor : Returns mapper definition and routing tier
curationProcessor    -> janusEngine_kafkaPublisher  : Passes canonical event envelope + target topic
janusEngine_kafkaPublisher -> janus-cloud-tier* : Publishes canonical event
kafkaIngestionAdapter -> janusEngine_healthAndMetrics : Emits processing metrics
```

## Related

- Architecture dynamic view: `components-janusEngineComponents`
- Related flows: [MBus Bridge Curation](mbus-bridge-curation.md), [DLQ Replay](dlq-replay.md), [Curator Metadata Refresh](curator-metadata-refresh.md)
