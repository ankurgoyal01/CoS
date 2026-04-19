---
service: "partner-service"
title: "partner-service Documentation"
generated: "2026-03-02T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumPartnerService, continuumPartnerServicePostgres]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard 2.x"
  runtime: "JVM 17"
---

# Partner Service Documentation

3PIP partner management, onboarding, and metrics service for the Continuum platform.

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
| Framework | Dropwizard 2.x + JTier 5.14.0 |
| Runtime | JVM 17 |
| Build tool | Maven 3 |
| Platform | Continuum |
| Domain | 3PIP Partner Management |
| Team | SOX Inscope / 3PIP |
