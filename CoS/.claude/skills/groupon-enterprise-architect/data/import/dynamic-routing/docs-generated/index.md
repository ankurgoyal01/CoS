---
service: "dynamic-routing"
title: "dynamic-routing Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumDynamicRoutingWebApp", "continuumDynamicRoutingMongoDb"]
tech_stack:
  language: "Java 1.8"
  framework: "Spring 4.2.6 / Apache Camel 2.17.7"
  runtime: "Tomcat (WAR)"
---

# Message Bus Dynamic Routing Documentation

Java web application that manages dynamic routes between JMS brokers (queues and topics) across Groupon's Global Message Bus infrastructure, enabling controlled cross-datacenter and cross-broker message flow with filtering and transformation.

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
| Language | Java 1.8 |
| Framework | Spring 4.2.6, Apache Camel 2.17.7 |
| Runtime | Tomcat (WAR deployment) |
| Build tool | Maven 3.x |
| Platform | Continuum (Global Message Bus) |
| Domain | Messaging Infrastructure |
| Team | GMB (Global Message Bus) — messagebus-team@groupon.com |
