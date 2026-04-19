---
service: "lgtm"
title: "Telemetry Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "telemetry-ingestion"
flow_type: asynchronous
trigger: "Instrumented Continuum workload emits OTLP spans and/or metrics"
participants:
  - "continuumOtelCollector"
  - "otelReceivers"
  - "otelExportPipelines"
  - "continuumTempo"
  - "tempoGatewayApi"
  - "tempoTraceStorage"
  - "metricsStack"
architecture_ref: "dynamic-telemetry-ingestion-and-query-flow"
---

# Telemetry Ingestion

## Summary

This flow covers the end-to-end path by which OpenTelemetry signals (traces and metrics) from instrumented Continuum workloads are received by the OTel Collector, processed, and delivered to their respective backends. Traces are forwarded to Grafana Tempo for durable storage, while metrics are exported to Thanos via Prometheus remote write. The flow is asynchronous and push-based — workloads push OTLP payloads without waiting for storage confirmation.

## Trigger

- **Type**: api-call (push)
- **Source**: Any Continuum workload instrumented with an OpenTelemetry SDK, configured to send to the OTel Collector's OTLP endpoint
- **Frequency**: Per-request / continuous — spans are batched and flushed at configurable intervals by the OpenTelemetry SDK

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Instrumented Workload | Emits OTLP spans and metrics | (external to LGTM) |
| OTLP Receivers | Receives inbound OTLP signals on gRPC (4317) and HTTP (4318) | `otelReceivers` |
| Export Pipelines | Batches, transforms, and routes signals to exporters | `otelExportPipelines` |
| Tempo Gateway API | Receives OTLP/HTTP trace write requests and routes to internal Tempo components | `tempoGatewayApi` |
| Tempo Trace Storage | Persists trace blocks to GCS | `tempoTraceStorage` |
| Thanos (metrics) | Receives metrics via Prometheus remote write | `metricsStack` |

## Steps

1. **Receive OTLP signal**: Instrumented workload pushes an OTLP traces or metrics payload to the OTel Collector.
   - From: Instrumented workload
   - To: `otelReceivers`
   - Protocol: OTLP/gRPC (port 4317) or OTLP/HTTP (port 4318)

2. **Batch and process**: The `batch` processor accumulates spans/metrics until the batch is ready for export. For metrics, the `transform` processor converts units (milliseconds to seconds for `http.server.duration` and `http.client.duration`) and the `metricstransform` processor renames metrics to OTel semantic convention names.
   - From: `otelReceivers`
   - To: `otelExportPipelines`
   - Protocol: Internal OTel pipeline

3. **Export traces to Tempo**: The `otlphttp/tempo` exporter sends trace batches to the Tempo Gateway.
   - From: `otelExportPipelines`
   - To: `tempoGatewayApi`
   - Protocol: OTLP/HTTP (`http://tempo-gateway.<namespace>`)

4. **Write trace blocks**: The Tempo Gateway routes spans to the Tempo distributor, which fans out to ingesters. Ingesters hold spans in memory and flush sealed blocks to GCS.
   - From: `tempoGatewayApi`
   - To: `tempoTraceStorage`
   - Protocol: Internal Tempo gRPC + GCS SDK

5. **Export metrics to Thanos**: The `prometheusremotewrite` exporter sends metric batches to the Thanos receive endpoint.
   - From: `otelExportPipelines`
   - To: `metricsStack`
   - Protocol: Prometheus remote write (HTTP POST to `/api/v1/receive`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Tempo Gateway unavailable | OTel Collector retries export (standard OTel exporter retry) | Spans queued in memory up to buffer limits; dropped if sustained outage |
| Thanos receive unavailable | OTel Collector retries export | Metrics dropped if buffer exhausted; no persistent queue |
| OTLP receiver port unavailable (Collector down) | Workload SDK retries based on its own retry config | Telemetry lost until Collector pod recovers; HPA may spin up additional replicas |
| GCS write failure (Tempo ingester) | Tempo logs error; data remains in memory until flush retry | Trace data at risk if ingester restarts before successful flush |

## Sequence Diagram

```
Workload -> otelReceivers: OTLP spans + metrics (gRPC:4317 or HTTP:4318)
otelReceivers -> otelExportPipelines: batch + transform + rename
otelExportPipelines -> tempoGatewayApi: OTLP/HTTP traces (http://tempo-gateway)
tempoGatewayApi -> tempoTraceStorage: write trace blocks to GCS
otelExportPipelines -> metricsStack: Prometheus remote write (http://thanos-receive:19291/api/v1/receive)
```

## Related

- Architecture dynamic view: `dynamic-telemetry-ingestion-and-query-flow`
- Related flows: [Oxygen Trace Routing](oxygen-trace-routing.md), [Trace Storage and Compaction](trace-storage-compaction.md), [Trace Query and Visualization](trace-query-visualization.md)
