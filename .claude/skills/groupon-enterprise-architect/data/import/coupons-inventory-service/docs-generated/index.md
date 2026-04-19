---
service: "coupons-inventory-service"
title: "coupons-inventory-service Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumCouponsInventoryService, continuumCouponsInventoryDb, continuumCouponsInventoryRedis, continuumCouponsInventoryMessageBus]
tech_stack:
  language: "Java"
  framework: "Dropwizard (JTIER)"
  runtime: "Java 8+"
---

# Coupons Inventory Service Documentation

Java/Dropwizard microservice within Groupon's Continuum platform that manages coupon inventory products, units, reservations, clicks, and availability through REST APIs, backed by Postgres, Redis caching, and IS Core Message Bus integration.

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
| Language | Java |
| Framework | Dropwizard (JTIER) |
| Runtime | Java 8+ |
| Build tool | Maven (inferred from JTIER conventions) |
| Platform | Continuum |
| Domain | Commerce / Coupon Inventory |
| Team | Inventory Engineering |
