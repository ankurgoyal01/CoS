---
service: "afl-rta"
title: "AFL RTA Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumAflRtaService, continuumAflRtaMySql]
tech_stack:
  language: "Java 21"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 21"
---

# AFL RTA (Affiliate Real-Time Attribution) Documentation

Consumes Janus-processed click and order events from Kafka, performs real-time marketing channel attribution, and publishes attributed orders to downstream partner systems via MBus.

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
| Framework | Dropwizard (JTier jtier-service-pom 5.15.0) |
| Runtime | JVM 21 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Affiliates / Marketing Attribution |
| Team | AFL (gpn-dev@groupon.com) |
