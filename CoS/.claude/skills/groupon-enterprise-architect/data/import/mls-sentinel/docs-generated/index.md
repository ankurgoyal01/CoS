---
service: "mls-sentinel"
title: "mls-sentinel Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMlsSentinelService, mlsSentinelDealIndexDb, mlsSentinelHistoryDb, mlsSentinelUnitIndexDb]
tech_stack:
  language: "Java 17"
  framework: "Dropwizard (JTier)"
  runtime: "JVM 17"
---

# MLS Sentinel Documentation

MLS Sentinel is the gatekeeper component of the Merchant Lifecycle System, consuming domain events from MessageBus and emitting fully-validated Kafka Command messages consumed primarily by MLS Yang.

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
| Language | Java 17 |
| Framework | Dropwizard via JTier 5.14.0 |
| Runtime | JVM 17 (Eclipse Temurin) |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Merchant Lifecycle System (MLS) |
| Team | Merchant Experience (bmx@groupon.com) |
