---
service: "mbus-isimud"
title: "mbus-isimud Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMbusIsimudService", "continuumMbusIsimudPostgres"]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard"
  runtime: "JVM 17"
---

# mbus-isimud (Message Bus Validation Service) Documentation

A message broker validation service that generates and executes randomized workloads against message broker systems to verify correctness, reliability, and performance during broker migrations.

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
| Language | Java 17 |
| Framework | Dropwizard (JTier) |
| Runtime | JVM 17 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Message Bus / Infrastructure |
| Team | Global Message Bus |
