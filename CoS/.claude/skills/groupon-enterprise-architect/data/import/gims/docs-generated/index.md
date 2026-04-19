---
service: "gims"
title: "GIMS Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [gims]
tech_stack:
  language: "Java"
  framework: "Continuum / JTier (inferred)"
  runtime: "Java / JVM"
---

# GIMS (Groupon Image Management Service) Documentation

Continuum service providing centralized image storage, transformation, and delivery for the Groupon platform, with Akamai CDN integration for edge delivery.

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
| Language | Java |
| Framework | Continuum / JTier (inferred) |
| Runtime | Java / JVM |
| Build tool | Maven (inferred) |
| Platform | Continuum |
| Domain | Shared Infrastructure / Media |
| Team | Media / Platform team |
