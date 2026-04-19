---
service: "lgtm"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for LGTM (Grafana Tempo + OpenTelemetry Collector + Grafana Dashboards).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Telemetry Ingestion](telemetry-ingestion.md) | asynchronous | Instrumented workload emits OTLP spans/metrics | OTel Collector receives OTLP signals and routes traces to Tempo and metrics to Thanos |
| [Oxygen Trace Routing](oxygen-trace-routing.md) | asynchronous | OTLP signals from Oxygen-related services | Filtered pipeline routes selected service traces and metrics to Elastic APM |
| [Trace Storage and Compaction](trace-storage-compaction.md) | batch | Tempo ingester block flush timer | Tempo ingesters flush sealed trace blocks to GCS; compactor merges blocks over time |
| [Trace Query and Visualization](trace-query-visualization.md) | synchronous | Engineer opens Grafana trace dashboard | Grafana queries Tempo Query Frontend and renders trace search results and detail views |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The `dynamic-telemetry-ingestion-and-query-flow` dynamic view in the central architecture model documents the full end-to-end flow across `continuumOtelCollector`, `continuumTempo`, `loggingStack`, `metricsStack`, and `continuumGrafana`. See the architecture dynamic view reference: `dynamic-telemetry-ingestion-and-query-flow`.

- [Telemetry Ingestion](telemetry-ingestion.md) — spans across `continuumOtelCollector` and `continuumTempo`
- [Oxygen Trace Routing](oxygen-trace-routing.md) — spans across `continuumOtelCollector` and `loggingStack`
- [Trace Storage and Compaction](trace-storage-compaction.md) — spans across `continuumTempo` and GCS
- [Trace Query and Visualization](trace-query-visualization.md) — spans across `continuumGrafana` and `continuumTempo`
