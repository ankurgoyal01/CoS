---
service: "HotzoneGenerator"
title: "HotzoneGenerator Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumHotzoneGeneratorJob"]
tech_stack:
  language: "Java 1.8"
  framework: "None (standalone batch jar)"
  runtime: "JVM 1.8"
---

# HotzoneGenerator Documentation

Scheduled Java batch job that generates geo-targeted deal hotzones and auto-category campaigns by aggregating deal, taxonomy, proximity, and deal-cluster data for the Groupon Emerging Channels proximity notification system.

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
| Language | Java 1.8 |
| Framework | None (standalone batch jar) |
| Runtime | JVM 1.8 |
| Build tool | Maven (assembly plugin, jar-with-dependencies) |
| Platform | Continuum |
| Domain | Proximity / Emerging Channels |
| Team | Emerging Channels (svc_emerging_channel) |
