---
service: "kafka-active-audit"
title: "kafka-active-audit Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuum"
  containers: ["continuumKafkaActiveAuditService"]
tech_stack:
  language: "Java 11"
  framework: "Apache Kafka Clients 0.10.2.1"
  runtime: "OpenJDK 11 (JRE)"
  build_tool: "Maven 3"
---

# Kafka Active Audit Documentation

Daemon that produces and consumes audit records on a dedicated Kafka topic, tracks message latency and missing messages, and emits operational health metrics to a centralized monitoring backend.

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
| Framework | Apache Kafka Clients 0.10.2.1 |
| Runtime | OpenJDK 11 JRE |
| Build tool | Maven (maven-shade-plugin, uber jar) |
| Platform | Continuum |
| Domain | Data Infrastructure / Kafka Observability |
| Team | Data Systems (data-systems-team@groupon.com) |
