---
service: "emailsearch-dataloader"
title: "emailsearch-dataloader Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumEmailSearchDataloaderService", "continuumEmailSearchPostgresDb", "continuumDecisionEnginePostgresDb", "continuumCampaignPerformanceMysqlDb"]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 17"
---

# Email Search Dataloader Documentation

A scheduled batch and event-driven service that processes email campaign performance data, evaluates A/B test statistical significance, makes automated treatment rollout decisions, and exports metrics to the Hive data warehouse.

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
| Framework | Dropwizard (JTier jtier-service-pom 5.14.1) |
| Runtime | JVM 17 |
| Build tool | Maven (mvnvm) |
| Platform | Continuum |
| Domain | Email / Push Campaign Optimization |
| Team | Rocketman |
