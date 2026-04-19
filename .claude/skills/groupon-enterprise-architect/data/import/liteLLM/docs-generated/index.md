---
service: "liteLLM"
title: "LiteLLM Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumLiteLlmGateway]
tech_stack:
  language: "Python 3.13"
  framework: "LiteLLM"
  runtime: "Python 3.13"
---

# LiteLLM Documentation

LiteLLM is a lightweight LLM gateway deployed within the Continuum platform that provides OpenAI-compatible API routing, multi-provider support, caching, and observability for AI/LLM workloads at Groupon.

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
| Language | Python 3.13 |
| Framework | LiteLLM |
| Runtime | Python 3.13 |
| Build tool | Docker (image pull + retag via GitHub Actions) |
| Platform | Continuum (GCP Kubernetes) |
| Domain | AI / LLM Infrastructure |
| Team | Conveyor Cloud |
