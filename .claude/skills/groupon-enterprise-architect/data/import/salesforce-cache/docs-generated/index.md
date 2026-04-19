---
service: "salesforce-cache"
title: "Salesforce Cache Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumSalesforceCacheDatabase, continuumSalesforceCacheRedis, salesforceCacheApi, salesforceCacheReplicationWorker]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 11"
---

# Salesforce Cache Documentation

A read-only cache of select Salesforce CRM data, exposing that data via a REST API to internal Groupon services.

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
| Framework | Dropwizard (JTier) |
| Runtime | JVM 11 |
| Build tool | Maven (jtier-service-pom 5.14.0) |
| Platform | Continuum |
| Domain | Salesforce Integration |
| Team | Salesforce Integration (sfint-dev@groupon.com) |
