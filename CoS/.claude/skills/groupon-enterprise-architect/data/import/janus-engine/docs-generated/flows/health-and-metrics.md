---
service: "janus-engine"
title: "Health and Metrics"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "health-and-metrics"
flow_type: scheduled
trigger: "Service startup and continuous runtime"
participants:
  - "continuumJanusEngine"
  - "janusOrchestrator"
  - "janusEngine_healthAndMetrics"
  - "mbusIngestionAdapter"
  - "kafkaIngestionAdapter"
  - "dlqProcessor"
  - "metricsStack"
architecture_ref: "components-janusEngineComponents"
---

# Health and Metrics

## Summary

Throughout its lifecycle, Janus Engine manages a filesystem-based liveness flag and continuously emits operational and streaming metrics to the metrics stack. The `janusEngine_healthAndMetrics` component is driven by `janusOrchestrator` on startup and updated by whichever adapter is active during normal operation. This flow covers both the health flag lifecycle (startup, healthy, unhealthy/shutdown) and the continuous metrics emission path to `metricsStack`.

## Trigger

- **Type**: schedule / lifecycle
- **Source**: Service startup (bootstrap by `janusOrchestrator`) and continuous runtime (periodic metric emission by active adapter)
- **Frequency**: Health flag written on startup; metrics emitted continuously during event processing

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Janus Engine Application (Orchestrator) | Bootstraps the service; initializes health flag on startup | `janusOrchestrator` |
| Health and Metrics | Writes/removes liveness flag; emits runtime metrics | `janusEngine_healthAndMetrics` |
| MBus Engine Adapter | Emits MBus-specific processing metrics | `mbusIngestionAdapter` |
| Kafka Streams Engine Adapter | Emits Kafka Streams runtime metrics | `kafkaIngestionAdapter` |
| DLQ Engine Adapter | Emits DLQ processing metrics | `dlqProcessor` |
| Metrics Stack | Receives all operational and streaming metrics | `metricsStack` |

## Steps

1. **Bootstrap and write liveness flag**: On startup, `janusOrchestrator` initializes the service, selects the engine mode, and instructs `janusEngine_healthAndMetrics` to write the filesystem liveness flag.
   - From: `janusOrchestrator`
   - To: `janusEngine_healthAndMetrics`
   - Protocol: direct

2. **Emit startup metrics**: `janusOrchestrator` emits initial runtime state metrics to `metricsStack` via `janusEngine_healthAndMetrics`.
   - From: `janusEngine_healthAndMetrics`
   - To: `metricsStack`
   - Protocol: SMA metrics (JTier)

3. **Continuous adapter metrics emission** (per active mode): The active adapter (`mbusIngestionAdapter`, `kafkaIngestionAdapter`, or `dlqProcessor`) emits per-event processing counters, throughput rates, and error counts to `janusEngine_healthAndMetrics`.
   - From: active adapter
   - To: `janusEngine_healthAndMetrics`
   - Protocol: direct

4. **Forward metrics to metricsStack**: `janusEngine_healthAndMetrics` aggregates and forwards all operational metrics to the external `metricsStack`.
   - From: `janusEngine_healthAndMetrics`
   - To: `metricsStack`
   - Protocol: SMA metrics

5. **Remove liveness flag on unhealthy state**: If a fatal error occurs (e.g., MBus connection lost, Kafka unreachable), `janusEngine_healthAndMetrics` removes the filesystem liveness flag, causing the Kubernetes liveness probe to fail and trigger a pod restart.
   - From: `janusEngine_healthAndMetrics`
   - To: filesystem (liveness flag file)
   - Protocol: exec (file system)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Metrics stack unreachable | Metrics emission fails silently or with retry | Processing continues; metrics may be lost for the interval |
| Fatal adapter error | Liveness flag removed | Kubernetes liveness probe fails; pod is restarted |
| Slow metrics emission | JTier metrics client buffers | No functional impact on event processing |

## Sequence Diagram

```
janusOrchestrator          -> janusEngine_healthAndMetrics : Write liveness flag (startup)
janusEngine_healthAndMetrics -> metricsStack               : Emit startup runtime metrics
activeAdapter              -> janusEngine_healthAndMetrics : Emit per-event processing metrics
janusEngine_healthAndMetrics -> metricsStack               : Forward aggregated metrics (continuous)
[on fatal error]
janusEngine_healthAndMetrics -> filesystem                 : Remove liveness flag
```

## Related

- Architecture dynamic view: `components-janusEngineComponents`
- Related flows: [Kafka Stream Curation](kafka-stream-curation.md), [MBus Bridge Curation](mbus-bridge-curation.md), [DLQ Replay](dlq-replay.md)
