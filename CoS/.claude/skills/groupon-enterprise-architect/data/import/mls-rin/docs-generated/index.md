---
service: "mls-rin"
title: "mls-rin Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumMlsRinService, mlsRinDealIndexDb, mlsRinHistoryDb, mlsRinMetricsDb, mlsRinUnitIndexDb, mlsRinYangDb]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 17"
---

# MLS RIN (Merchant Lifecycle System Read Interface) Documentation

HTTP read-only interface for Merchant Lifecycle System data, exposing deal index, unit search, metrics, history, CLO transactions, insights, and merchant risk APIs to Merchant Center and internal consumers.

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
| Framework | Dropwizard (JTier jtier-service-pom 5.14.0) |
| Runtime | JVM 17 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Merchant Lifecycle / Merchant Experience |
| Team | Merchant Experience (MerchantCenter-BLR@groupon.com) |
