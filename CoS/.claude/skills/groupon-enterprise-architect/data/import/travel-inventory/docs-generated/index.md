---
service: "travel-inventory"
title: "travel-inventory Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumTravelInventoryService, continuumTravelInventoryCron, continuumTravelInventoryDb, continuumTravelInventoryHotelProductCache, continuumTravelInventoryInventoryProductCache, continuumBackpackAvailabilityCache, continuumAwsSftpTransfer, continuumContentService, continuumBackpackReservationService]
tech_stack:
  language: "Java 8"
  framework: "Jersey / Skeletor"
  runtime: "Tomcat on GCP"
---

# Getaways Inventory Service Documentation

Getaways Inventory Service is the authoritative backend for hotel inventory, room types, rate plans, availability, and reservation management within Groupon's Getaways vertical.

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
| Language | Java 8 |
| Framework | Jersey / Skeletor |
| Runtime | Tomcat on GCP |
| Build tool | Maven (assumed) |
| Platform | Continuum |
| Domain | Getaways / Travel Inventory |
| Team | Getaways Inventory |
