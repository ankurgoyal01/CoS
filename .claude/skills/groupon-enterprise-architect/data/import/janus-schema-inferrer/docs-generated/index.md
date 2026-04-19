---
service: "janus-schema-inferrer"
title: "janus-schema-inferrer Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumJanusSchemaInferrer]
tech_stack:
  language: "Java/Scala 2.12"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 11"
---

# Janus Schema Inferrer Documentation

Samples real-time messages from Kafka and MBus, infers JSON schemas using Apache Spark, and publishes discovered schemas and raw sample messages to the Janus metadata service.

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
| Language | Java / Scala 2.12.13 |
| Framework | Dropwizard (JTier jtier-service-pom 5.14.0) |
| Runtime | JVM 11 (Eclipse Temurin) |
| Build tool | Maven 3.x |
| Platform | Continuum (Data Engineering) |
| Domain | Data Ingestion / Schema Management |
| Team | dnd-ingestion (platform-data-eng@groupon.com) |
