---
service: "inventory_outbound_controller"
title: "inventory_outbound_controller Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuum"
  containers: [continuumInventoryOutboundController, continuumInventoryOutboundControllerDb]
tech_stack:
  language: "Java OpenJDK 8"
  framework: "Play Framework 2.2"
  runtime: "JVM Java 8"
---

# Goods Outbound Controller Documentation

Core logistics orchestration service for Continuum's physical goods business, managing end-to-end fulfillment lifecycle from manifest ingestion through shipment tracking, cancellation, and GDPR-compliant account erasure.

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
| Language | Java OpenJDK 8 |
| Framework | Play Framework 2.2 |
| Runtime | JVM Java 8 |
| Build tool | SBT |
| Platform | continuum |
| Domain | Logistics & Fulfillment |
| Team | Goods & Logistics |
