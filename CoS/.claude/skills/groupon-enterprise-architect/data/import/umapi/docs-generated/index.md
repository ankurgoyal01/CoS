---
service: "umapi"
title: "Universal Merchant API (UMAPI) Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumUniversalMerchantApi]
tech_stack:
  language: "Java"
  framework: "Vert.x"
  runtime: "JVM"
---

# Universal Merchant API (UMAPI) Documentation

Centralized API for merchant lifecycle operations: onboarding, updates, search, reporting, and aggregation for Merchant Center and platform consumers.

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
| Framework | Vert.x |
| Runtime | JVM |
| Build tool | Gradle (inferred) |
| Platform | Continuum |
| Domain | Identity, Auth & User Data / Merchant Platform |
| Team | Merchant Platform |
