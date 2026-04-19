---
service: "lgtm"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 2
---

# Integrations

## Overview

The LGTM stack integrates with three external backends (GCS for trace storage, Elastic APM for Oxygen service observability, and Thanos for metrics) and two internal Continuum platform dependencies (the logging stack and metrics stack). All integrations are outbound push from the OTel Collector or Tempo components. No inbound integrations from external systems exist — telemetry signals arrive from Continuum workloads instrumented with OpenTelemetry SDKs.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Cloud Storage (GCS) | GCS SDK (Workload Identity) | Durable trace block storage for Tempo | yes | `tempoTraceStorage` |
| Elastic APM | OTLP/HTTP | Receives filtered Oxygen service traces and metrics | no | `loggingStack` |
| Thanos (Prometheus remote write) | Prometheus remote write (HTTP) | Receives all metrics exported by the OTel Collector | yes | `metricsStack` |

### Google Cloud Storage (GCS) Detail

- **Protocol**: GCS SDK via GKE Workload Identity
- **Base URL / SDK**: GCS buckets — see [Data Stores](data-stores.md) for bucket names
- **Auth**: GKE Workload Identity annotation (`iam.gke.io/gcp-service-account`) on the Tempo Kubernetes service account
- **Purpose**: Tempo uses GCS as its object storage backend for all trace block writes, reads, and compaction
- **Failure mode**: If GCS is unavailable, Tempo ingesters continue holding data in memory up to configured limits; once memory is exhausted, ingestion will degrade
- **Circuit breaker**: No evidence found in codebase

### Elastic APM Detail

- **Protocol**: OTLP/HTTP
- **Base URL / SDK**: `http://elastic-apm-http.logging-platform-elastic-stack-staging:8200` (staging) / `http://elastic-apm-http.logging-platform-elastic-stack-production:8200` (production)
- **Auth**: TLS enabled with `insecure_skip_verify: true`
- **Purpose**: Receives traces and metrics for specific Oxygen-related services (`spring-boot-oxygen`, `sem-blacklist-service`, `umapi`) via the `traces/oxygen` and `metrics/oxygen` OTel Collector pipelines
- **Failure mode**: The OTel Collector pipeline will retry; if APM is unavailable, Oxygen traces are lost for affected services — general traces still flow to Tempo
- **Circuit breaker**: No evidence found in codebase

### Thanos (Prometheus Remote Write) Detail

- **Protocol**: Prometheus remote write (HTTP)
- **Base URL / SDK**: `http://thanos-receive.telegraf-staging:19291/api/v1/receive` (staging) / `http://thanos-receive.telegraf-production:19291/api/v1/receive` (production)
- **Auth**: None (cluster-internal)
- **Purpose**: All metrics received by the OTel Collector are exported to Thanos via the `metrics` pipeline after unit conversion and rename transforms
- **Failure mode**: If Thanos is unavailable, metrics are dropped; the OTel Collector does not buffer undelivered metrics persistently
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Continuum instrumented workloads | OTLP/gRPC (4317), OTLP/HTTP (4318) | Source of all trace and metric telemetry pushed to the OTel Collector | `continuumOtelCollector` |
| Logging Stack (Elastic) | OTLP/HTTP | Destination for Oxygen-filtered traces and metrics | `loggingStack` |
| Metrics Stack (Thanos) | Prometheus remote write | Destination for all collected metrics | `metricsStack` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Grafana Dashboards (`continuumGrafana`) | HTTP (Tempo Query API / TraceQL) | Queries Tempo for trace search and drill-down views |
| Platform engineers and SRE | HTTP (Grafana UI) | Use Grafana trace dashboards for debugging and incident response |

> Upstream instrumented workload consumers are tracked in the central architecture model.

## Dependency Health

> No evidence found in codebase for explicit health check, retry, or circuit breaker configurations beyond standard Kubernetes liveness/readiness probes provided by the Helm charts. Tempo and the OTel Collector rely on Kubernetes pod restarts and HPA-based scaling as the primary resilience mechanism.
