---
service: "bynder-integration-service"
title: "bynder-integration-service Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumBynderIntegrationService, continuumBynderIntegrationMySql]
tech_stack:
  language: "Java 11"
  framework: "JTier (Dropwizard-based) 5.14.1"
  runtime: "Java 11 / OpenJDK 11"
---

# Bynder Integration Service Documentation

Integrates Bynder DAM with Groupon's image service, syncing images and metadata as the single source of truth for the Editorial team.

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
| Framework | JTier (Dropwizard-based) 5.14.1 |
| Runtime | Java 11 / OpenJDK 11 |
| Build tool | Maven 3 |
| Platform | Continuum |
| Domain | Editorial / Digital Asset Management |
| Team | Editorial / Gazebo team (gazebo-dev@groupon.com) |
