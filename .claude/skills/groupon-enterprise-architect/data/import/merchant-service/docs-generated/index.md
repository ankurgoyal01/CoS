---
service: "merchant-service"
title: "M3 Merchant Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumM3MerchantService", "continuumMerchantServiceMySql", "continuumMerchantServiceRedis"]
tech_stack:
  language: "Java 21"
  framework: "Spring MVC 6.2.0"
  runtime: "Apache Tomcat 11.0 (JRE 21 Temurin)"
---

# M3 Merchant Service Documentation

The M3 Merchant Service is the authoritative source of truth for Groupon merchant data, providing CRUD operations for merchants, account contacts, features, and configurations, and synchronizing merchant records with downstream commerce systems.

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
| Language | Java 21 |
| Framework | Spring MVC 6.2.0 |
| Runtime | Apache Tomcat 11.0 (JRE 21 Temurin) |
| Build tool | Maven 3 |
| Platform | Continuum |
| Domain | Merchant Data |
| Team | Merchant Data (merchantdata@groupon.com) |
