---
service: "goods-inventory-service-routing"
title: "Goods Inventory Service Routing Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumGoodsInventoryServiceRouting", "continuumGoodsInventoryServiceRoutingDb"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier jtier-service-pom 5.7.3)"
  runtime: "JVM 11"
---

# Goods Inventory Service Routing Documentation

Routes inventory product requests to the correct regional Goods Inventory Service (GIS) endpoint by resolving the shipping region for each inventory product UUID, and maintains a local shipping-region store to support that routing decision.

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
| Framework | Dropwizard (via JTier jtier-service-pom 5.7.3) |
| Runtime | JVM 11 |
| Build tool | Maven (mvnvm + JTier parent POM) |
| Platform | Continuum |
| Domain | Goods / Inventory / Logistics |
| Team | RAPT (inventory@groupon.com) |
