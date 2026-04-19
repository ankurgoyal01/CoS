---
service: "watson-realtime"
title: "watson-realtime Documentation"
generated: "2026-03-03T00:00:00Z"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAnalyticsKsService, continuumCookiesService, continuumDealviewService, continuumRealtimeKvService, continuumRvdService, continuumUserIdentitiesService, continuumKsTableTrimmerService]
tech_stack:
  language: "Java 11"
  framework: "Kafka Streams 2.7.0"
  runtime: "JVM 11"
---

# watson-realtime Documentation

Kafka Streams data writer jobs that process Janus events in real time and persist analytics counters, cookie mappings, deal view counts, realtime KV data, RVD aggregations, and user identities into Redis, Cassandra/Keyspaces, and PostgreSQL for downstream consumption by watson-api.

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
| Framework | Kafka Streams 2.7.0 |
| Runtime | JVM 11 |
| Build tool | Maven |
| Platform | Continuum |
| Domain | Search Ranking / Analytics |
| Team | dnd-ds-search-ranking@groupon.com |
