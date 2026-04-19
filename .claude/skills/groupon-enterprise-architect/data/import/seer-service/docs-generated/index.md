---
service: "seer-service"
title: "seer-service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSeerService"
  containers: [continuumSeerService, continuumSeerServicePostgres]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 17"
---

# Seer Service Documentation

Engineering metrics aggregation service that collects, stores, and serves data from Jira, Jenkins, GitHub, Deploybot, OpsGenie, and SonarQube to support engineering-effectiveness reporting at Groupon.

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
| Framework | Dropwizard via JTier (`jtier-service-pom` 5.14.1) |
| Runtime | JVM 17 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Engineering Effectiveness / Developer Productivity |
| Team | svuppalapati |
