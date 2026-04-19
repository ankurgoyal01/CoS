---
service: "badges-service"
title: "Badges Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumBadgesService", "continuumBadgesRedis"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 11 (Eclipse Temurin)"
---

# Badges Service Documentation

Powers deal badge annotations (Top Seller, Trending, Selling Fast, Recently Viewed, etc.) and urgency messages across Groupon web, email, and mobile surfaces via RAPI.

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
| Runtime | JVM 11 |
| Build tool | Maven |
| Platform | Continuum (deal-platform) |
| Domain | Deal Merchandising / Badges |
| Team | deal-catalog-dev@groupon.com |
