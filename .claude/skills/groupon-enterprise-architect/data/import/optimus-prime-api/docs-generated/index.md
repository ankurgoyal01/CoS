---
service: "optimus-prime-api"
title: "optimus-prime-api Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumOptimusPrimeApi, continuumOptimusPrimeApiDb, continuumOptimusPrimeGcsBucket, continuumOptimusPrimeS3Storage]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard (JTier v5.14.0)"
  runtime: "Java 17 / JTier"
---

# Optimus Prime API Documentation

Manages ETL job definitions, scheduling, orchestration, and run status tracking for data pipelines.

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
| Framework | Dropwizard (JTier v5.14.0) |
| Runtime | Java 17 / JTier |
| Build tool | Maven 3.x |
| Platform | continuum |
| Domain | Data Integration and ETL (DnD Tools) |
| Team | DnD Tools |
