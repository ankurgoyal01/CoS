---
service: "mailman"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Transactional Notifications"
platform: "Continuum"
team: "Rocketman-India-Team (balsingh)"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Spring Boot"
  framework_version: "1.2.2"
  runtime: "JVM"
  runtime_version: "Java 11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Mailman Overview

## Purpose

Mailman is the transactional email orchestration service for the Continuum platform. It receives transactional notification requests via HTTP API or MBus, aggregates contextual data from downstream domain services (orders, users, deals, inventory, merchants), and publishes enriched `TransactionalEmailRequest` payloads to MBus for delivery by Rocketman. It also enforces deduplication, manages retry state, and runs scheduled batch retry jobs.

## Scope

### In scope

- Accepting transactional email requests via REST API (`POST /mailman/mail`)
- Consuming `MailmanQueue` messages from MBus and dispatching them to the workflow engine
- Aggregating domain context from Orders, Users, Deal Catalog, Marketing Deal, Voucher Inventory, Relevance API, Universal Merchant API, API Lazlo, Goods Inventory, Travel Itinerary, and ThirdParty Inventory
- Duplicate detection via `POST /mailman/duplicate-check` and PostgreSQL-backed deduplication state
- Manual retry submission via `POST /mailman/retry`
- Scheduled batch retry processing via Quartz 2.2.1
- Client registration and context management via `POST /mailman/client` and `POST /mailman/context`
- Publishing enriched `TransactionalEmailRequest` events to MBus for Rocketman
- Dead letter queue (DLQ) consumption and error recovery

### Out of scope

- Actual email rendering and delivery (handled by Rocketman)
- Marketing/bulk email campaigns (separate platform)
- User preference and subscription management
- Email template management and storage

## Domain Context

- **Business domain**: Transactional Notifications
- **Platform**: Continuum
- **Upstream consumers**: Any Continuum service or event producer requiring transactional email dispatch; MBus producers writing to `MailmanQueue`
- **Downstream dependencies**: MBus (`messageBus`), Rocketman, Orders, Users, Deal Catalog, Marketing Deal, Voucher Inventory, Relevance API, Universal Merchant API, API Lazlo, Goods Inventory, Travel Itinerary, ThirdParty Inventory, `mailmanPostgres`

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | Rocketman-India-Team (balsingh) |
| Primary Consumer | Rocketman — consumes enriched payloads from MBus for delivery |
| Platform | Continuum — provides upstream domain context data |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | Summary inventory |
| Framework | Spring Boot | 1.2.2 | Summary inventory |
| Build tool | Maven | — | Summary inventory |
| Scheduler | Quartz | 2.2.1 | Summary inventory |
| Database | PostgreSQL | 13.1 | Summary inventory |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| spring-boot-starter-web | 1.2.2 | http-framework | HTTP server and MVC controllers |
| spring-boot-starter-actuator | 1.2.2 | metrics | Health check and metrics endpoints |
| spring-boot-starter-security | 1.2.2 | auth | Endpoint security |
| postgresql JDBC | 42.2.15 | db-client | PostgreSQL connectivity |
| quartz | 2.2.1 | scheduling | Scheduled batch retry jobs |
| springfox-swagger2 | 2.6.1 | validation | API documentation and contract exposure |
| metrics-core | 3.1.0 | metrics | Application-level metrics instrumentation |
| jackson-databind | 2.4.5 | serialization | JSON serialization/deserialization |
| ehcache | 2.9.0 | state-management | In-memory caching |
| guava | 19.0 | validation | Utility support (collections, preconditions) |
| gson | 2.2.4 | serialization | Supplementary JSON serialization |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
