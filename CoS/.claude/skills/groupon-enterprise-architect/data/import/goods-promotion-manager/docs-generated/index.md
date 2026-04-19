---
service: "goods-promotion-manager"
title: "Goods Promotion Manager Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumGoodsPromotionManagerService"
  containers: ["continuumGoodsPromotionManagerService", "continuumGoodsPromotionManagerDb"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 11"
---

# Goods Promotion Manager Documentation

Internal tool that enables Groupon merchandise teams to create, manage, and submit goods promotions, replacing manual spreadsheet-based workflows with an API-driven process backed by automated pricing and eligibility checks.

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
| Runtime | JVM 11 (Eclipse Temurin) |
| Build tool | Maven |
| Platform | Continuum (Goods / Inventory domain) |
| Domain | Goods Promotions / Inventory Lifecycle Staging |
| Team | Goods Engineering Seattle |
