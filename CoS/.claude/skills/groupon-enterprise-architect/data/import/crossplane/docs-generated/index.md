---
service: "crossplane"
title: "crossplane Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["crossplaneController", "crossplaneRbacManager"]
tech_stack:
  language: "YAML (Kubernetes DSL)"
  framework: "Crossplane 1.19.1"
  runtime: "Kubernetes"
---

# Crossplane Documentation

Crossplane is a Kubernetes add-on that enables Groupon platform teams to provision and manage GCP cloud infrastructure (GCS buckets and related resources) through declarative Kubernetes-native APIs, abstracting provider-specific details behind custom composite resource definitions.

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
| Language | YAML (Kubernetes DSL) |
| Framework | Crossplane 1.19.1 |
| Runtime | Kubernetes |
| Build tool | Helm v3 |
| Platform | Continuum / Conveyor |
| Domain | Infrastructure Platform |
| Team | Cloud Core / Conveyor |
