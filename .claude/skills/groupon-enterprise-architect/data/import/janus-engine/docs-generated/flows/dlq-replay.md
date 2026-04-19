---
service: "janus-engine"
title: "DLQ Replay"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "dlq-replay"
flow_type: event-driven
trigger: "Failed event present in a MBus dead-letter queue"
participants:
  - "messageBus"
  - "continuumJanusEngine"
  - "dlqProcessor"
  - "curationProcessor"
  - "janusMetadataClientComponent"
  - "janusEngine_kafkaPublisher"
  - "janusEngine_healthAndMetrics"
architecture_ref: "dynamic-dlqReprocessFlow"
---

# DLQ Replay

## Summary

In `DLQ` mode, Janus Engine acts as a dead-letter queue reprocessor. The `dlqProcessor` component subscribes to MBus dead-letter queues, retrieves events that previously failed curation (during MBUS or standard processing), loads updated mapper/retry metadata from the Janus metadata service, and runs them through the same `curationProcessor` pipeline. Successfully curated events are published to the standard Janus Kafka sink topics, effecting recovery without manual intervention.

## Trigger

- **Type**: event
- **Source**: Failed event present in a MBus dead-letter queue (populated by failed curation attempts in MBUS mode)
- **Frequency**: Continuous while deployed in DLQ mode; typically deployed as a remediation action following a curation failure incident

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus (DLQ) | Holds failed events awaiting reprocessing | `messageBus` |
| Janus Engine (DLQ mode) | Hosts the DLQ reprocessor runtime | `continuumJanusEngine` |
| DLQ Engine Adapter | Consumes dead-letter queue; drives reprocessing pipeline | `dlqProcessor` |
| Curator Processor | Reprocesses failed event payload through curation transformation | `curationProcessor` |
| Janus Metadata Client | Supplies updated mapper definitions and retry rules | `janusMetadataClientComponent` |
| Kafka Publisher | Publishes recovered canonical event to Janus sink topic | `janusEngine_kafkaPublisher` |
| Health and Metrics | Emits DLQ processing metrics | `janusEngine_healthAndMetrics` |

## Steps

1. **DLQ delivers failed event**: `messageBus` delivers a dead-letter payload to `continuumJanusEngine` running in DLQ mode.
   - From: `messageBus` (DLQ topic)
   - To: `dlqProcessor`
   - Protocol: MBus (mbus-client 1.5.2)

2. **Adapter receives DLQ payload**: `dlqProcessor` receives the failed event and initiates reprocessing.
   - From: `messageBus`
   - To: `dlqProcessor`
   - Protocol: MBus

3. **Fetch updated mapper metadata**: `curationProcessor` requests the current mapper definition and retry rules for the event's source topic and event type. This may return updated mappings if the original failure was due to a schema mismatch.
   - From: `curationProcessor`
   - To: `janusMetadataClientComponent`
   - Protocol: direct (in-process cache; HTTP via curator-api 0.0.41)

4. **Apply curation and transform**: `curationProcessor` applies the (potentially updated) mapper definition to the failed payload, normalizes fields via json-path, and produces a canonical Janus event envelope.
   - From: `dlqProcessor`
   - To: `curationProcessor`
   - Protocol: direct

5. **Publish recovered event**: `janusEngine_kafkaPublisher` publishes the successfully curated event to the appropriate Janus Kafka sink topic.
   - From: `curationProcessor` → `janusEngine_kafkaPublisher`
   - To: `janus-cloud-tier1`, `janus-cloud-tier2`, `janus-cloud-tier3`, `janus-cloud-impression`, `janus-cloud-email`, or `janus-cloud-raw`
   - Protocol: Kafka (kafka-clients 2.7.0)

6. **Emit DLQ metrics**: `dlqProcessor` and `janusEngine_healthAndMetrics` emit reprocessing counters and DLQ drain rate metrics to `metricsStack`.
   - From: `dlqProcessor`, `janusEngine_healthAndMetrics`
   - To: `metricsStack`
   - Protocol: SMA metrics

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Curation still fails after retry | Event cannot be normalized even with updated mappers | Event is re-enqueued to DLQ or discarded after max retries (policy managed externally); alert should fire |
| Mapper still not found | `curationProcessor` returns error; `dlqProcessor` cannot proceed | Event logged; mapper must be added to Janus metadata service before replay can succeed |
| Kafka publish failure | Kafka producer retries (at-least-once) | Event retried; persistent failure halts DLQ drain |
| Metadata service unreachable | Cached metadata used; risk of repeating same failure | DLQ processing continues with stale mappers; may re-fail the same event |

## Sequence Diagram

```
messageBus (DLQ)   -> dlqProcessor              : Delivers dead-letter payload
dlqProcessor       -> curationProcessor          : Passes failed payload for reprocessing
curationProcessor  -> janusMetadataClientComponent : Requests updated mapper/retry rules
janusMetadataClientComponent --> curationProcessor : Returns (updated) mapper definition
curationProcessor  -> janusEngine_kafkaPublisher  : Passes recovered canonical event + target topic
janusEngine_kafkaPublisher -> janus-cloud-tier*   : Publishes recovered Janus event
dlqProcessor       -> janusEngine_healthAndMetrics : Emits DLQ processing metrics
```

## Related

- Architecture dynamic view: `dynamic-dlqReprocessFlow`
- Related flows: [MBus Bridge Curation](mbus-bridge-curation.md), [Kafka Stream Curation](kafka-stream-curation.md), [Curator Metadata Refresh](curator-metadata-refresh.md)
