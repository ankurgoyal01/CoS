---
service: "user-behavior-collector"
title: "User Behavior Collector Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumUserBehaviorCollectorJob, continuumDealViewNotificationDb, continuumDealInfoRedis]
tech_stack:
  language: "Java 1.8"
  framework: "Apache Spark 2.4.8"
  runtime: "JVM (Java 1.8)"
---

# User Behavior Collector Documentation

Scheduled batch job that collects user behavior signals from Janus Kafka event files via Spark/YARN, persists deal views, purchases, searches, ratings, and email-open events to PostgreSQL, refreshes deal metadata in Redis, updates wishlists, and publishes segmented audiences to downstream notification systems.

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
| Framework | Apache Spark 2.4.8 |
| Runtime | JVM (Java 1.8) |
| Build tool | Maven (maven-shade-plugin 3.2.1) |
| Platform | Continuum |
| Domain | Emerging Channels / Triggered Notifications |
| Team | Emerging Channels |
