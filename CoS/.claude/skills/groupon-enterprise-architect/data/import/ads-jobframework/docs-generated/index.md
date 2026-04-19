---
service: "ads-jobframework"
title: "ads-jobframework Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumAdsJobframeworkSpark, continuumAdsJobframeworkHiveWarehouse, continuumAdsJobframeworkMySql, continuumAdsJobframeworkTeradata, continuumAdsJobframeworkGcsBucket]
tech_stack:
  language: "Scala 2.12"
  framework: "Apache Spark 2.4"
  runtime: "JVM / YARN"
  build_tool: "sbt"
---

# Ads Job Framework Documentation

Big data batch processing framework for all Groupon ads reporting, sponsored listing analytics, third-party attribution feeds, and uplift modeling workloads.

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
| Language | Scala 2.12.8 |
| Framework | Apache Spark 2.4.0 |
| Runtime | JVM / YARN |
| Build tool | sbt (with sbt-assembly) |
| Platform | Continuum |
| Domain | Ads / Sponsored Listings |
| Team | ads-eng@groupon.com |
