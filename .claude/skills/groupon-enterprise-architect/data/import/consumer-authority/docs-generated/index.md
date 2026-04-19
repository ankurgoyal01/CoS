---
service: "consumer-authority"
title: "consumer-authority Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumConsumerAuthorityService, continuumConsumerAuthorityWarehouse]
tech_stack:
  language: "Scala"
  framework: "Apache Spark"
  runtime: "Spark on Hadoop/YARN"
---

# Consumer Authority Documentation

Scala/Spark batch pipeline that computes and publishes 500+ consumer attributes across NA/INTL/GBL regions for approximately 500 million Groupon users, delivering results to the Consumer Authority Warehouse and the Groupon Message Bus.

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
| Language | Scala |
| Framework | Apache Spark |
| Runtime | Spark on Hadoop/YARN |
| Build tool | SBT |
| Platform | Continuum |
| Domain | Data Engineering / Consumer Analytics |
| Team | Data Engineering |
