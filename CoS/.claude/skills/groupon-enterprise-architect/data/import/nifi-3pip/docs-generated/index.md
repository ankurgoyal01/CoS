---
service: "nifi-3pip"
title: "nifi-3pip Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [nifiNode1, nifiNode2, nifiNode3, zookeeper]
tech_stack:
  language: "Java (JVM)"
  framework: "Apache NiFi 2.4.0"
  runtime: "Apache NiFi 2.4.0 (Docker)"
---

# Nifi - Third Party Inventory Documentation

Apache NiFi cluster deployment providing third-party inventory (3PIP) data ingestion capabilities for the Continuum platform.

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
| Language | Java (JVM) |
| Framework | Apache NiFi 2.4.0 |
| Runtime | Apache NiFi 2.4.0 (Docker) |
| Build tool | Docker / Helm |
| Platform | Continuum |
| Domain | Third-Party Inventory (3PIP) |
| Team | 3pip-cbe-eng@groupon.com |
