---
service: "inbox_management_platform"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Communication / Marketing"
platform: "Continuum"
team: "Push - Inbox Management (dgupta)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Custom daemon framework"
  framework_version: ""
  runtime: "openjdk"
  runtime_version: "11"
  build_tool: "Maven"
  build_tool_version: "3"
  package_manager: "Maven"
---

# InboxManagement Overview

## Purpose

InboxManagement (inbox_management_platform) is the communication orchestration layer responsible for coordinating email, push, and SMS campaign sends across Groupon's Continuum platform. It receives campaign send events from Campaign Management, applies arbitration filtering via CAS, schedules dispatch work, and publishes final send events to RocketMan for channel delivery. The service also manages user attribute synchronization and provides an admin control plane for runtime configuration.

## Scope

### In scope

- Receiving and processing CampaignSendEvents from Campaign Management
- Loading and refreshing user attributes from the Enterprise Data Warehouse (EDW)
- Applying arbitration/suppression filtering via the CAS (Campaign Arbitration Service)
- Coordinating calculation-to-dispatch workflows using Redis-backed priority queues
- Publishing final SendEvents to RocketMan for email/push/SMS delivery
- Managing send error state and error recovery workflows
- Consuming SubscriptionEvents to maintain preference state
- Exposing an admin UI and REST API for runtime config, throttle rates, daemon flags, and circuit breakers
- Monitoring queue depth and emitting health metrics

### Out of scope

- Actual channel delivery (email SMTP, push APNS/FCM, SMS gateway) — handled by RocketMan
- Campaign creation and targeting logic — handled by Campaign Management
- User profile authority — user attributes are sourced from EDW; InboxManagement only caches/syncs them
- Arbitration/suppression rule evaluation — handled by CAS

## Domain Context

- **Business domain**: Communication / Marketing
- **Platform**: Continuum
- **Upstream consumers**: Campaign Management (publishes CampaignSendEvents), User Profile system (publishes UserProfileEvents)
- **Downstream dependencies**: RocketMan (channel dispatch), CAS (arbitration), Campaign Management API (campaign data), EDW (user attributes), Redis, PostgreSQL, Kafka

## Stakeholders

| Role | Description |
|------|-------------|
| Team lead | dgupta — Push / Inbox Management team |
| Consumers | Campaign Management, RocketMan |
| Operations | On-call engineers for the Push - Inbox Management team |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | Summary / Dockerfile (openjdk:11) |
| Framework | Custom daemon framework | — | Summary (coord-worker, dispatcher, user-sync, etc.) |
| Runtime | openjdk | 11 | Dockerfile base image |
| Build tool | Maven | 3 | Summary |
| Package manager | Maven | — | pom.xml |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| guice | 4.2.2 | dependency-injection | Runtime dependency injection for daemon components |
| mbus-client | 1.2.9 | message-client | Internal message bus client for event consumption |
| jedis | 2.6.1 | db-client | Redis client for queue, lock, and transient state operations |
| kafka_2.12 | 0.10.2.1 | message-client | Kafka consumer/producer for domain events (UserProfile, Errors, Subscriptions) |
| postgresql-jdbc | 42.3.6 | db-client | JDBC driver for PostgreSQL config and error state store |
| hive-jdbc | 2.0.0 | db-client | JDBC driver for Hive/EDW user attribute loading |
| logback-steno | 1.8.0 | logging | Structured JSON logging |
| arpnetworking-metrics-client | 0.3.2 | metrics | Metrics emission for queue depth and health monitoring |
| typesafe-config | 1.3.0 | configuration | Hierarchical application configuration via HOCON files |
| gson | 2.2.4 | serialization | JSON serialization/deserialization for event payloads |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
