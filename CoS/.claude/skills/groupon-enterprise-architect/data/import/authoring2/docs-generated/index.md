---
service: "authoring2"
title: "authoring2 Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAuthoring2Service", "continuumAuthoring2Postgres", "continuumAuthoring2Queue"]
tech_stack:
  language: "Java 11"
  framework: "Jersey/JAX-RS 2.35"
  runtime: "Apache Tomcat 7.0.109"
---

# Authoring2 Documentation

Authoring2 is Groupon's Taxonomy Authoring Service — the system of record for creating, editing, and deploying Groupon's product and deal category taxonomy to the live TaxonomyV2 serving tier.

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
| Framework | Jersey/JAX-RS 2.35 |
| Runtime | Apache Tomcat 7.0.109 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Taxonomy |
| Team | taxonomy (taxonomy-dev@groupon.com) |
