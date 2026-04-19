---
service: "mls-yang"
title: "mls-yang Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSmaMetrics"
  containers: [continuumSmaMetricsApi, continuumSmaMetricsBatch, mlsYangDb, mlsYangRinDb, mlsYangHistoryDb, mlsYangDealIndexDb]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (jtier-service-pom 5.14.0)"
  runtime: "JVM 11"
---

# Merchant Lifecycle Service Yang (mls-yang) Documentation

The Yang component of the Merchant Lifecycle Service (MLS): consumes MLS command events from Kafka, projects merchant lifecycle state into PostgreSQL read models, and runs scheduled batch imports of deal metrics and inventory data.

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
| Framework | Dropwizard (via jtier-service-pom 5.14.0) |
| Runtime | JVM 11 |
| Build tool | Maven |
| Platform | Continuum (MLS domain) |
| Domain | Merchant Lifecycle / Merchant Analytics |
| Team | Merchant Experience (MerchantCenter-BLR@groupon.com) |
