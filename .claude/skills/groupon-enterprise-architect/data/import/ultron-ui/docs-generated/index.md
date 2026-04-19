---
service: "ultron-ui"
title: "ultron-ui Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumUltronUiWeb]
tech_stack:
  language: "Java 8"
  framework: "Play Framework 2.4.8"
  runtime: "openjdk 8"
---

# Ultron UI Documentation

Data integration job orchestration UI — a stateless Play Framework web application that proxies operator requests to the Ultron API backend.

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
| Language | Java 8 |
| Framework | Play Framework 2.4.8 |
| Runtime | openjdk 8 |
| Build tool | SBT 0.13.18 |
| Platform | Continuum |
| Domain | Data & D Platform — ingestion job orchestration |
| Team | dnd-ingestion |
