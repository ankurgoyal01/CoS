---
service: "orders_mbus_client"
title: "orders_mbus_client Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumOrdersMbusClient"
  containers: ["continuumOrdersMbusClient", "continuumOrdersMbusClientMessageStore"]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard"
  runtime: "JVM (OpenJDK 11)"
---

# Orders Mbus Client (JOMC) Documentation

Message bus bridge service for the Groupon Orders platform — subscribes to MBus topics, routes events to the Orders service via HTTP, and publishes outbound gift-order events with durable retry semantics.

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
| Framework | Dropwizard (jtier-service-pom 5.14.0) |
| Runtime | JVM — AdoptOpenJDK 11 (UBI) |
| Build tool | Maven (mvnvm.properties) |
| Platform | Continuum |
| Domain | Orders / Payments |
| Team | Orders (orders-eng@groupon.com) |
