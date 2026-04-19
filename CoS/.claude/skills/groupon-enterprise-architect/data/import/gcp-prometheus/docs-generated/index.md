---
service: "gcp-prometheus"
title: "gcp-prometheus Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers:
    - "prometheusServer"
    - "prometheusConveyor"
    - "prometheusBlackboxExporter"
    - "grafana"
    - "thanosReceive"
    - "thanosQuery"
    - "thanosQueryFrontend"
    - "thanosStoreGateway"
    - "thanosCompact"
    - "thanosObjectStorage"
tech_stack:
  language: "YAML / Bash"
  framework: "Helm v3"
  runtime: "Kubernetes (GKE)"
---

# Thanos-Prometheus GCP Documentation

Platform for near real-time ingestion, long-term storage, and visualization of metrics across Groupon's GCP infrastructure, using Prometheus for scraping and Thanos for scalable global query and retention management.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints, contracts, protocols |
| [Events](events.md) | Async messages published and consumed |
| [Data Stores](data-stores.md) | Databases, caches, storage |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment, flags, secrets |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure and environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | YAML / Bash |
| Framework | Helm v3 |
| Runtime | Kubernetes (GKE) |
| Build tool | Jenkins (java-pipeline-dsl) |
| Platform | GCP |
| Domain | Metrics / Observability |
| Team | Metrics Team (metrics-platform-team@groupon.com) |
