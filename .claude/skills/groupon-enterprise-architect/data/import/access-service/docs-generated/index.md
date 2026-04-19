---
service: "mx-merchant-access"
title: "Merchant Access Service Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumAccessService", "continuumAccessPostgres"]
tech_stack:
  language: "Java 11"
  framework: "Spring MVC 4.2.0"
  runtime: "Apache Tomcat 8.5.73"
---

# Merchant Access Service Documentation

The Merchant Access Service (MAS) is the central authorization service managing which merchant-users have access to which merchants, under which roles and application-level rights.

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
| Framework | Spring MVC 4.2.0.RELEASE |
| Runtime | Apache Tomcat 8.5.73 (JRE 11 Temurin) |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Merchant Experience (MX) |
| Team | Merchant Experience — MerchantCenter-BLR@groupon.com |
