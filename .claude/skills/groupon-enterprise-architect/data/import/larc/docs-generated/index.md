---
service: "larc"
title: "larc Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumTravelLarcService, continuumTravelLarcDatabase]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard"
  runtime: "JVM"
---

# Travel Lowest Available Rate Calculator (LARC) Documentation

LARC automates hotel market pricing ingestion from QL2, calculates the lowest available nightly rate across all travel windows for Getaways booking deals, and publishes computed rates to the Travel Inventory Service.

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
| Framework | Dropwizard (jtier-service-pom 5.14.0) |
| Runtime | JVM |
| Build tool | Maven 3.3.9 |
| Platform | Continuum / Getaways |
| Domain | Travel — Hotel Rate Management |
| Team | Getaways Engineering (getaways-eng@groupon.com) |
