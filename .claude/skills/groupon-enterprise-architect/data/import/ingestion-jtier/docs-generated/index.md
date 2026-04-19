---
service: "ingestion-jtier"
title: "ingestion-jtier Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumIngestionJtierService, continuumIngestionJtierPostgres, continuumIngestionJtierRedis]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard 5.15.0"
  runtime: "JVM 11"
---

# ingestion-jtier Documentation

3PIP partner feed ingestion and deal creation service — ingests third-party inventory partner feeds, transforms offer data, and drives deal creation within the Continuum commerce platform.

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
| Framework | Dropwizard 5.15.0 |
| Runtime | JVM 11 |
| Build tool | Maven 3.5+ |
| Platform | Continuum |
| Domain | 3PIP Partner Feed Ingestion |
| Team | 3PIP Ingestion (3pip-cbe-eng@groupon.com, vaarora) |
