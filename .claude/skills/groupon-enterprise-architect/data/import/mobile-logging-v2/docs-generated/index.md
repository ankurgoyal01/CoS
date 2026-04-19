---
service: "mobile-logging-v2"
title: "mobile-logging-v2 Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMobileLoggingService]
tech_stack:
  language: "Java 11"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 11"
---

# Mobile Logging V2 Documentation

The Mobile Logging Service (MLS) accepts MessagePack-encoded log files from iOS and Android clients, decodes and normalises GRP telemetry events, and publishes them to the Kafka topic `mobile_tracking` for downstream analytics processing.

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
| Framework | Dropwizard (JTier 5.14.1) |
| Runtime | JVM 11 (prod-java11-jtier:3) |
| Build tool | Maven |
| Platform | Continuum (GCP) |
| Domain | Mobile Analytics / Data Engineering |
| Team | DA (da-communications@groupon.com) |
