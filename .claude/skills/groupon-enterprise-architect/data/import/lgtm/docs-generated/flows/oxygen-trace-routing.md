---
service: "lgtm"
title: "Oxygen Trace Routing"
generated: "2026-03-03"
type: flow
flow_name: "oxygen-trace-routing"
flow_type: asynchronous
trigger: "OTLP signals received from Oxygen-related services (spring-boot-oxygen, sem-blacklist-service, umapi)"
participants:
  - "otelReceivers"
  - "otelExportPipelines"
  - "loggingStack"
architecture_ref: "dynamic-telemetry-ingestion-and-query-flow"
---

# Oxygen Trace Routing

## Summary

The Oxygen Trace Routing flow is a specialised parallel pipeline within the OTel Collector that selectively filters OTLP traces and metrics originating from specific Oxygen-related services and forwards them to Elastic APM. This runs concurrently with the main telemetry ingestion flow — Oxygen service signals are both stored in Tempo (via the main `traces` pipeline) and forwarded to Elastic APM (via the `traces/oxygen` and `metrics/oxygen` pipelines). The filter is applied by the `filter/apm` processor based on the `service.name` resource attribute.

## Trigger

- **Type**: api-call (push)
- **Source**: Instrumented workloads with `service.name` equal to `spring-boot-oxygen`, `sem-blacklist-service`, or `umapi`
- **Frequency**: Per-request / continuous — same cadence as the general telemetry ingestion flow

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| OTLP Receivers | Receives all inbound OTLP signals including those from Oxygen services | `otelReceivers` |
| Export Pipelines | Applies `filter/apm` processor and routes matching signals to Elastic APM | `otelExportPipelines` |
| Elastic APM (loggingStack) | Receives Oxygen-filtered traces and metrics for APM analysis | `loggingStack` |

## Steps

1. **Receive OTLP signal**: OTLP traces and metrics from any instrumented workload arrive at `otelReceivers`.
   - From: Instrumented workload
   - To: `otelReceivers`
   - Protocol: OTLP/gRPC (port 4317) or OTLP/HTTP (port 4318)

2. **Apply Oxygen filter**: The `filter/apm` processor in the `traces/oxygen` and `metrics/oxygen` pipelines evaluates the `service.name` attribute. Spans and metrics where `service.name` matches `spring-boot-oxygen`, `sem-blacklist-service`, or `umapi` pass through; all others are dropped from this pipeline.
   - From: `otelReceivers`
   - To: `otelExportPipelines` (filter/apm processor)
   - Protocol: Internal OTel pipeline

3. **Batch filtered signals**: The `batch` processor accumulates filtered spans and metrics ready for export.
   - From: `otelExportPipelines` (filter/apm)
   - To: `otelExportPipelines` (batch processor)
   - Protocol: Internal OTel pipeline

4. **Export to Elastic APM**: The `otlp/elastic` exporter sends filtered traces and metrics to the Elastic APM endpoint.
   - From: `otelExportPipelines`
   - To: `loggingStack` (Elastic APM)
   - Protocol: OTLP/HTTP (`http://elastic-apm-http.<logging-namespace>:8200`), TLS with `insecure_skip_verify: true`

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Elastic APM unavailable | OTel exporter retries; `error_mode: ignore` on transform processors | Oxygen traces lost for affected window; main traces pipeline to Tempo is unaffected |
| Service name filter miss | Signals not matching filter are silently dropped from the Oxygen pipeline | Correct behaviour — non-Oxygen services do not reach Elastic APM via this pipeline |
| OTel Collector pod restart | In-flight buffered signals are lost | Transient gap in Elastic APM trace data; auto-recovery on pod restart |

## Sequence Diagram

```
Workload (service.name=spring-boot-oxygen) -> otelReceivers: OTLP spans + metrics
otelReceivers -> otelExportPipelines: route to traces/oxygen + metrics/oxygen pipelines
otelExportPipelines -> otelExportPipelines: filter/apm (pass: spring-boot-oxygen, sem-blacklist-service, umapi)
otelExportPipelines -> otelExportPipelines: batch
otelExportPipelines -> loggingStack: OTLP/HTTP to elastic-apm-http:8200
```

## Related

- Architecture dynamic view: `dynamic-telemetry-ingestion-and-query-flow`
- Related flows: [Telemetry Ingestion](telemetry-ingestion.md)
- OTel Collector filter configuration: `otel-collector/.meta/deployment/cloud/components/collector/common.yml` (`filter/apm` processor)
