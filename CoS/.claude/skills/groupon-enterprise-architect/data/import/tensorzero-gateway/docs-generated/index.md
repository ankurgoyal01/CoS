---
service: "tensorzero-gateway"
title: "tensorzero-gateway Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumGateway", "continuumClickhouse", "continuumUserInterface"]
tech_stack:
  language: "N/A (pre-built images)"
  framework: "TensorZero"
  runtime: "Docker / Kubernetes"
---

# Tensorzero Gateway Documentation

A modular AI gateway system providing LLM request routing, analytics persistence via ClickHouse, and an operator UI — deployed as three coordinated Kubernetes components within the Continuum Platform.

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
| Language | N/A (pre-built vendor images) |
| Framework | TensorZero 2025.6.3 |
| Runtime | Docker / Kubernetes |
| Build tool | Jenkins (`dockerBuildPipeline`) + Helm 3 (`cmf-generic-api` chart v3.90.2) |
| Platform | Continuum |
| Domain | AI / LLM Routing |
| Team | Conveyor Cloud |
