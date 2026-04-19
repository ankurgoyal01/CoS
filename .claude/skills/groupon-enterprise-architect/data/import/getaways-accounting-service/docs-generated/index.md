---
service: "getaways-accounting-service"
title: "Getaways Accounting Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumGetawaysAccountingService"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (jtier-service-pom 5.14.0)"
  runtime: "JVM"
---

# Getaways Accounting Service (GAS) Documentation

Dropwizard service that exposes finance and reservations search REST APIs and produces daily accounting CSV reports for Getaways hotel bookings.

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
| Build tool | Maven |
| Platform | Continuum |
| Domain | Getaways / Travel Accounting |
| Team | Getaways Engineering (getaways-eng@groupon.com) |
