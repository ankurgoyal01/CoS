---
service: "lgtm"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Observability / Telemetry"
platform: "Continuum"
team: "Platform Engineering"
status: active
tech_stack:
  language: "YAML / Shell"
  language_version: ""
  framework: "Helm"
  framework_version: "3"
  runtime: "Kubernetes"
  runtime_version: "GKE"
  build_tool: "Helm 3 + Krane"
  package_manager: "Helm"
---

# LGTM Overview

## Purpose

LGTM is Groupon's observability stack for distributed tracing and metrics collection within the Continuum Platform. It ingests OpenTelemetry signals (traces and metrics) from instrumented workloads, stores trace data durably in GCS-backed Grafana Tempo, and provides Grafana dashboards for trace exploration and drill-down. It also selectively routes traces and metrics for specific services (Oxygen) to Elastic APM, and exports all metrics via Prometheus remote write to Thanos.

## Scope

### In scope
- Receiving OTLP traces and metrics from instrumented Continuum services (gRPC port 4317, HTTP port 4318)
- Routing traces to Grafana Tempo for durable storage in GCS
- Exporting filtered Oxygen-service traces and metrics to Elastic APM
- Exporting metrics via Prometheus remote write to Thanos
- Providing Grafana dashboards for trace search and trace detail drill-down
- Multi-region deployment across `us-central1` and `europe-west1` on GCP GKE clusters

### Out of scope
- Log ingestion and aggregation (Loki integration is commented out and not enabled)
- Application-level instrumentation — services are instrumented separately using OpenTelemetry SDKs
- Metrics querying and alerting rules — owned by the metrics stack (Thanos/Prometheus)
- Elastic APM management — owned by the logging platform

## Domain Context

- **Business domain**: Observability / Telemetry
- **Platform**: Continuum
- **Upstream consumers**: Instrumented Continuum workloads sending OTLP signals; Grafana dashboards querying Tempo
- **Downstream dependencies**: GCS buckets (trace storage), Thanos receive endpoint (metrics), Elastic APM (Oxygen traces/metrics)

## Stakeholders

| Role | Description |
|------|-------------|
| Platform Engineering | Owns deployment, configuration, and operation of the LGTM stack |
| Service Developers | Consumers of trace dashboards for debugging and latency analysis |
| SRE / On-call | Uses Grafana trace dashboards during incident investigation |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Tracing Backend | Grafana Tempo (distributed) | 2.7.0 | `tempo/.meta/deployment/cloud/charts/tempo-distributed/Chart.yaml` |
| Telemetry Collector | OpenTelemetry Collector Contrib | 0.118.0 | `otel-collector/.meta/deployment/cloud/charts/opentelemetry-collector/Chart.yaml` |
| Helm Chart (Tempo) | tempo-distributed | 1.32.0 | `tempo/.meta/deployment/cloud/charts/tempo-distributed/Chart.yaml` |
| Helm Chart (OTel) | opentelemetry-collector | 0.115.0 | `otel-collector/.meta/deployment/cloud/charts/opentelemetry-collector/Chart.yaml` |
| Visualization | Grafana | 11.4.0 (dashboard plugin version) | `grafana/dashboards/trace_details.json` |
| Orchestration | Kubernetes (GKE) | — | `.deploy_bot.yml` |
| Build tool | Helm 3 + Krane | — | `.meta/deployment/cloud/scripts/deploy.sh` |
| CI/CD | Jenkins (Groovy DSL pipeline) | — | `Jenkinsfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| tempo-distributed Helm chart | 1.32.0 | deployment | Deploys Tempo in microservice mode (distributor, ingester, querier, compactor, query-frontend, gateway) |
| opentelemetry-collector Helm chart | 0.115.0 | deployment | Deploys OTel Collector in deployment mode with autoscaling |
| minio (Helm dep) | 4.0.12 | storage | Optional MinIO sub-chart bundled with Tempo for local storage |
| rollout-operator (Helm dep) | 0.23.0 | scheduling | Enables progressive rollout for Tempo components |
| grafana-agent-operator (Helm dep) | 0.5.0 | metrics | Meta-monitoring of Tempo via Grafana Agent |
| krane | — | deployment | Kubernetes resource deployment tool used by deploy scripts |
