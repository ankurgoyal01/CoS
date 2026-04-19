---
service: "lgtm"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [otlp-grpc, otlp-http, http]
auth_mechanisms: []
---

# API Surface

## Overview

The LGTM stack exposes two categories of API surface: telemetry ingestion endpoints (provided by the OpenTelemetry Collector) and trace query endpoints (provided by the Grafana Tempo Gateway and Query Frontend). Ingestion endpoints receive OTLP signals from instrumented workloads. Query endpoints are used by Grafana dashboards for trace search and trace detail retrieval. No external authentication mechanisms are configured on these endpoints — access is controlled at the Kubernetes network level.

## Endpoints

### OpenTelemetry Collector — Telemetry Ingestion

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| — | `${MY_POD_IP}:4317` (gRPC) | OTLP gRPC receiver — accepts trace and metric signals from instrumented workloads | None (network-controlled) |
| POST | `${MY_POD_IP}:4318` (HTTP) | OTLP HTTP receiver — accepts trace and metric signals from instrumented workloads | None (network-controlled) |

### Tempo Gateway — Trace Ingestion and Query

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `http://tempo-gateway/` | Receives OTLP/HTTP trace write requests from the OTel Collector | None (cluster-internal) |
| GET | `http://tempo-gateway/` | Routes trace query requests to the Query Frontend | None (cluster-internal) |

### Tempo Query Frontend — Trace Search

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST | Tempo HTTP Query API | TraceQL search queries from Grafana — returns trace list and trace detail | None (cluster-internal) |

### Prometheus Remote Write (Outbound — Collector to Thanos)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `http://thanos-receive:19291/api/v1/receive` (staging) | Pushes metrics via Prometheus remote write protocol | None (cluster-internal) |
| POST | `http://thanos-receive.telegraf-production:19291/api/v1/receive` (production) | Pushes metrics via Prometheus remote write protocol | None (cluster-internal) |

### Elastic APM (Outbound — Collector to Elastic)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `http://elastic-apm-http:8200` | Exports selected Oxygen service traces and metrics to Elastic APM via OTLP | TLS (insecure_skip_verify: true) |

## Request/Response Patterns

### Common headers

> No evidence found in codebase. Headers are standard OTLP/HTTP or Prometheus remote write protocol headers; no custom headers are configured in the collector pipelines.

### Error format

> No evidence found in codebase. Error handling follows standard OTLP receiver and Tempo gateway error responses. The OTel Collector pipeline is configured with `error_mode: ignore` for metric transform processors.

### Pagination

> Not applicable. Tempo trace queries return paginated results managed by the Grafana Tempo Query Frontend natively; no custom pagination is implemented.

## Rate Limits

> No rate limiting configured. Autoscaling (HPA) governs throughput capacity — see [Deployment](deployment.md) for replica ranges.

## Versioning

The Tempo HTTP API version follows the Grafana Tempo application version (2.7.0). OTLP protocol version is determined by the OpenTelemetry Collector Contrib version (0.118.0). No URL-path versioning is applied to internal cluster endpoints.

## OpenAPI / Schema References

> No evidence found in codebase. The OTLP protocol is defined by the OpenTelemetry specification. The Tempo query API is documented at https://grafana.com/docs/tempo/latest/api_docs/.
