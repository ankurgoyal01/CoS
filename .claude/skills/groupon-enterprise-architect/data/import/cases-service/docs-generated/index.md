---
service: "cases-service"
title: "Merchant Cases Service (MCS) Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumMerchantCaseService", "continuumMerchantCaseRedis"]
tech_stack:
  language: "Java 21"
  framework: "Dropwizard / JTier 5.14.0"
  runtime: "JVM 21"
---

# Merchant Cases Service (MCS) Documentation

The Merchant Cases Service (MCS) manages merchant support case workflows by acting as an orchestration layer between Groupon's Merchant Center and Salesforce CRM.

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
| Framework | Dropwizard / JTier 5.14.0 |
| Runtime | JVM (Eclipse Temurin) |
| Build tool | Maven 3.5.2+ |
| Platform | Continuum |
| Domain | Merchant Experience |
| Team | Merchant Experience (echo-dev@groupon.com) |
