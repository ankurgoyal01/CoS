---
service: "marketplace-ticketing-service"
title: "Marketplace Ticketing Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumMarketplaceTicketingService, continuumMarketplaceTicketingPostgres]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 11"
---

# Marketplace Ticketing Service Documentation

Microservice responsible for fetching, creating, and updating support tickets in Salesforce on behalf of Groupon marketplace merchants and internal operations teams.

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
| Framework | Dropwizard (JTier jtier-service-pom 5.14.0) |
| Runtime | JVM 11 (prod-java11-jtier) |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Goods / Marketplace Supply |
| Team | Goods Supply Tech |
