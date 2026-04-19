---
service: "amsJavaScheduler"
title: "AMS Java Scheduler Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAmsJavaScheduler, continuumAmsSchedulerScheduleStore]
tech_stack:
  language: "Java 8"
  framework: "cron4j 2.2.3"
  runtime: "JVM"
---

# AMS Java Scheduler Documentation

Cron-driven scheduler service that loads schedule definitions and triggers AMS audience materialization and EDW feedback jobs across NA and EMEA regions.

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
| Framework | cron4j 2.2.3 |
| Runtime | JVM |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Audience Management (CRM) |
| Team | audience-eng@groupon.com |
