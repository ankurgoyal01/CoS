---
service: "transporter-jtier"
title: "transporter-jtier Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumTransporterJtierService, continuumTransporterMysqlDatabase, continuumTransporterRedisCache]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (jtier-service-pom 5.14.0)"
  runtime: "JVM"
---

# Transporter JTier Documentation

Backend service that handles user requests from Transporter ITier and performs bulk data operations against Salesforce via scheduled Quartz jobs.

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
| Domain | Salesforce Integration |
| Team | Salesforce Integration (sfint-dev@groupon.com) |
