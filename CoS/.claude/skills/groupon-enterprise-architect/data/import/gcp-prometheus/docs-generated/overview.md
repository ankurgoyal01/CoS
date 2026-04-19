---
service: "gcp-prometheus"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Metrics / Observability"
platform: "GCP"
team: "Metrics Team"
status: active
tech_stack:
  language: "YAML / Bash"
  language_version: ""
  framework: "Helm"
  framework_version: "v3"
  runtime: "Kubernetes (GKE)"
  runtime_version: ""
  build_tool: "Jenkins"
  package_manager: "Helm"
---

# Thanos-Prometheus GCP Overview

## Purpose

`gcp-prometheus` is Groupon's GCP-hosted metrics platform that combines Prometheus scraping with Thanos for long-term, multi-region metric storage and global querying. It collects metrics from Kubernetes workloads and infrastructure targets, ships time-series data to scalable object storage (GCS), and exposes a unified query layer consumed by Grafana dashboards and alert evaluators. The platform provides near real-time analysis of metrics across production and staging environments in `us-central1` and `europe-west1`.

## Scope

### In scope

- Prometheus metric scraping from Kubernetes targets via `prometheusServer` and `prometheusConveyor`
- Blackbox probing of endpoints via `prometheusBlackboxExporter`
- Federation of metrics between Prometheus instances via `prometheusConveyor`
- Remote-write ingestion into Thanos (`thanosReceive`) with replication
- Long-term storage of metric blocks in GCS (`thanosObjectStorage`)
- Block compaction, down-sampling, and retention management via `thanosCompact`
- Historical block serving via sharded `thanosStoreGateway` (thanos-store-1, thanos-store-2, thanos-store-3)
- Unified global query via `thanosQuery` and `thanosQueryFrontend` (with query splitting and caching)
- Visualization and dashboarding via Grafana (v10.4.1 / v11.4.0)
- Okta-based authentication for Grafana

### Out of scope

- Log aggregation and shipping (handled by the Logging Platform / Filebeat stack)
- Alert rule management and notification routing (PagerDuty integration managed externally via `metrics-platform-team@groupon.pagerduty.com`)
- Application-level metric instrumentation in service code
- Kafka or stream-based metric ingestion pipelines

## Domain Context

- **Business domain**: Metrics / Observability
- **Platform**: GCP (Google Cloud Platform)
- **Upstream consumers**: Grafana dashboards (internal engineers), alert evaluation systems, PagerDuty (via alertmanager)
- **Downstream dependencies**: GCS (Thanos Object Storage), Kubernetes API server, Okta (Grafana auth), Kafka (Filebeat log shipping), Jaeger (distributed tracing)

## Stakeholders

| Role | Description |
|------|-------------|
| Metrics Team | Owns and operates the platform (`metrics-platform-team@groupon.com`) |
| Cloud Native Team | Manages GKE clusters and GCP project access |
| Service Engineers | Consumers of Grafana dashboards and alerting |
| SRE On-call | Responds to PagerDuty alerts via `metrics-platform-team@groupon.pagerduty.com` |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Container images | Thanos | v0.30.2 / v0.31.0 / v0.32.2 | `charts/thanos-groupon-stack/templates/prd/*.yaml` |
| Container images | Grafana | 10.4.1 / 11.4.0 | `charts/grafana/templates/prd/deployment.yaml` |
| Container images | Filebeat | 7.17.6 | `charts/thanos-groupon-stack/templates/prd/thanos-receive-sts.yaml` |
| Packaging | Helm | v3 | `charts/thanos-groupon-stack/Chart.yaml`, `deploy-gcp.sh` |
| Orchestration | Kubernetes (GKE) | — | `.deploy_bot.yml`, `deploy-gcp.sh` |
| CI/CD | Jenkins | — | `Jenkinsfile` (java-pipeline-dsl@latest-2) |
| Deploy tooling | krane | — | `deploy-gcp.sh` |
| Object storage | GCS | — | `models/containers.dsl`, Kubernetes secret `thanos-objectstorage` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Thanos Receive | v0.30.2 | metrics | Accepts Prometheus remote-write, serves Store API |
| Thanos Query | v0.31.0 | metrics | Aggregates queries across store gateways and receives |
| Thanos Store | v0.31.0 / v0.32.2 | metrics | Serves historical blocks from GCS object storage |
| Thanos Compact | v0.30.2 | metrics | Compacts and down-samples blocks in GCS |
| Grafana | 10.4.1 / 11.4.0 | ui-framework | Visualization and dashboarding |
| Filebeat | 7.17.6 | logging | Log shipping sidecar to Kafka |
| Prometheus (server) | — | metrics | Metric scraping and short-term TSDB |
| Jaeger | — | tracing | Distributed tracing for Thanos components (rate-limiting sampler) |

> Only the most important libraries are listed here. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
