---
service: "etorch"
title: "etorch Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumEtorchApp, continuumEtorchWorker]
tech_stack:
  language: "Java 11"
  framework: "JAX-RS/Jersey 2.43"
  runtime: "Jetty 9.4.51"
---

# eTorch Documentation

Extranet Travel ORCHestrator — the merchant-facing Getaways API enabling hotel operators to manage inventory, deals, accounting, and contacts on the Groupon Getaways platform.

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
| Language | Java 11 |
| Framework | JAX-RS/Jersey 2.43 |
| Runtime | Jetty 9.4.51 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Getaways / Extranet (Merchant-facing hotel operations) |
| Team | Getaways Engineering (getaways-eng@groupon.com) |
