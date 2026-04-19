---
service: "gpn-data-api"
title: "gpn-data-api Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumGpnDataApiService", "continuumGpnDataApiMySql"]
tech_stack:
  language: "Java 21"
  framework: "Dropwizard (JTier 5.15.0)"
  runtime: "JVM 21"
---

# GPN Data API Documentation

Backend API service that provides marketing attribution data for Groupon orders, enabling analysis of which marketing channels are driving purchases. Consumed by the `sem-ui` service (Attribution Lens) and affiliate analytics tooling.

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
| Language | Java 21 |
| Framework | Dropwizard via JTier 5.15.0 |
| Runtime | JVM 21 (Eclipse Temurin) |
| Build tool | Maven |
| Platform | Continuum (Groupon Conveyor Cloud / GCP) |
| Domain | Affiliate Marketing / Analytics |
| Team | AFL (gpn-dev@groupon.com) |
