---
service: "lgtm"
title: "lgtm Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumTempo, continuumOtelCollector, continuumGrafana]
tech_stack:
  language: "YAML / Shell"
  framework: "Helm"
  runtime: "Kubernetes"
---

# LGTM Documentation

Groupon's distributed tracing and telemetry observability stack — comprising Grafana Tempo, an OpenTelemetry Collector, and Grafana Dashboards — deployed on GCP Kubernetes clusters for the Continuum Platform.

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
| Language | YAML / Shell |
| Framework | Helm |
| Runtime | Kubernetes (GKE) |
| Build tool | Helm 3 + Krane |
| Platform | Continuum |
| Domain | Observability / Telemetry |
| Team | Platform Engineering |
