---
service: "lgtm"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumTempo, continuumOtelCollector, continuumGrafana]
---

# Architecture Context

## System Context

LGTM is a sub-system of the `continuumSystem` (Continuum Platform), Groupon's core commerce engine. It operates as the observability layer, sitting between instrumented Continuum services that emit OTLP telemetry and external backends that store or display it. Instrumented workloads push OTLP signals to the `continuumOtelCollector`, which fans out traces to `continuumTempo` for storage and to the `loggingStack` (Elastic APM) for Oxygen-filtered traces. Metrics are pushed to the `metricsStack` (Thanos). Grafana queries `continuumTempo` to render trace dashboards for engineers.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Tempo | `continuumTempo` | Backend Service | Grafana Tempo (distributed) | 2.7.0 | Distributed tracing backend deployed from the Tempo Helm chart. Receives, stores, and serves traces. |
| OpenTelemetry Collector | `continuumOtelCollector` | Telemetry Agent | OpenTelemetry Collector Contrib | 0.118.0 | Receives OTLP signals and routes traces/metrics to observability backends. |
| Grafana Dashboards | `continuumGrafana` | Visualization | Grafana | 11.4.0+ | Trace exploration dashboards configured to query Tempo. |

## Components by Container

### Tempo (`continuumTempo`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Gateway API (`tempoGatewayApi`) | Ingress/API gateway that receives and routes trace ingestion and query traffic. Entry point for all OTLP write and query requests from the OTel Collector and Grafana. | Tempo Gateway (nginx-based) |
| Query Frontend API (`tempoQueryApi`) | Query endpoint used by Grafana trace dashboards. Provides the TraceQL and HTTP search API for retrieving stored traces. | Tempo Query Frontend |
| Trace Storage Backend (`tempoTraceStorage`) | Persistent block storage for trace data, backed by GCS buckets per environment and region. | Tempo Storage + GCS |

### OpenTelemetry Collector (`continuumOtelCollector`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| OTLP Receivers (`otelReceivers`) | Listens on gRPC (port 4317) and HTTP (port 4318) for OTLP trace and metric signals from instrumented workloads. | OTel Receiver |
| Export Pipelines (`otelExportPipelines`) | Processes and routes telemetry: traces to Tempo via OTLP/HTTP, filtered Oxygen traces/metrics to Elastic APM, and all metrics via Prometheus remote write to Thanos. | OTel Pipeline |

### Grafana Dashboards (`continuumGrafana`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Trace Dashboards (`grafanaTraceDashboards`) | Dashboard definitions providing trace list search and drill-down trace detail views. Queries `tempoQueryApi` for rendering. | Grafana Dashboards |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `otelReceivers` | `otelExportPipelines` | Processes telemetry and routes data to exporters | Internal OTel pipeline |
| `otelExportPipelines` | `tempoGatewayApi` | Sends traces via OTLP/HTTP | OTLP/HTTP |
| `otelExportPipelines` | `loggingStack` | Exports selected Oxygen traces to Elastic APM | OTLP/HTTP |
| `otelExportPipelines` | `metricsStack` | Exports metrics via Prometheus remote write | Prometheus remote write (HTTP) |
| `tempoGatewayApi` | `tempoTraceStorage` | Writes and queries trace blocks | Internal Tempo gRPC |
| `grafanaTraceDashboards` | `tempoQueryApi` | Queries traces for dashboard views | HTTP (TraceQL / Tempo API) |
| `continuumGrafana` | `continuumTempo` | Queries trace data | HTTP |
| `continuumOtelCollector` | `continuumTempo` | Exports traces | OTLP/HTTP |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component (Tempo): `components-tempo`
- Component (OTel Collector): `components-otel-collector`
- Component (Grafana): `components-grafana`
- Dynamic (telemetry flow): `dynamic-telemetry-ingestion-and-query-flow`
