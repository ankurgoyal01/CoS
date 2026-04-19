---
service: "maris"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Getaways / Travel Inventory"
platform: "Continuum"
team: "Getaways Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.0"
  runtime: "JVM"
  runtime_version: "Java 11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# MARIS Overview

## Purpose

MARIS (Hotel Inventory and Reservation Integration Service) is the Getaways platform service responsible for managing hotel room availability, inventory unit state, and the full reservation lifecycle. It acts as the primary integration point with Expedia EAN and Expedia Rapid APIs, translating Groupon's internal inventory and order model into Expedia booking operations and surfacing hotel content and pricing to downstream Groupon consumers.

## Scope

### In scope

- Fetching and exposing hotel room availability and market rates via the Expedia Rapid API
- Creating, confirming, and cancelling hotel reservations with Expedia
- Managing inventory unit lifecycle — status transitions, redemption recording, and state persistence in `marisMySql`
- Processing order status change events from the Orders Service to trigger payment capture, reversal, and cancellation workflows
- Publishing inventory unit update events and snapshot events to the message bus for downstream consumers
- Handling GDPR erasure requests and publishing completion events
- Running scheduled batch jobs for refund synchronization and cancellation processing

### Out of scope

- Hotel content authoring and metadata management (handled by Content Service)
- Travel search and ranking (handled by Travel Search Service)
- Payment processing and financial settlement (handled by Orders Service)
- Deal creation and catalog management (handled by Deal Catalog Service)

## Domain Context

- **Business domain**: Getaways / Travel Inventory
- **Platform**: Continuum
- **Upstream consumers**: Travel Search Service, Deal Catalog Service, internal Groupon commerce flows
- **Downstream dependencies**: Expedia EAN API, Expedia Rapid API, Content Service, Orders Service, Deal Catalog Service, MBus (message bus)

## Stakeholders

| Role | Description |
|------|-------------|
| Getaways Engineering | Service owner — develops and operates MARIS |
| Getaways Product | Defines hotel inventory and booking business rules |
| Platform Engineering | Maintains JTier / Dropwizard framework dependencies |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | pom.xml |
| Framework | Dropwizard / JTier | 5.14.0 | pom.xml (is-core 3.0.55, jtier-daas-mysql) |
| Runtime | JVM | Java 11 | pom.xml |
| Build tool | Maven | — | pom.xml |
| Package manager | Maven | — | pom.xml |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| is-core (Spaceman iCore) | 3.0.55 | http-framework | Dropwizard-based service core and iCore resource facades |
| jtier-daas-mysql | — | db-client | JTier managed MySQL data access layer |
| jtier-migrations | — | db-client | Database schema migration support |
| jtier-messagebus-client | — | message-client | MBus JMS topic/queue publishing and consumption |
| jtier-retrofit | — | http-framework | Typed HTTP client wrappers for downstream service calls |
| jtier-quartz-bundle | — | scheduling | Quartz-based scheduled job execution (refund sync, cancellation processing) |
| HikariCP | 5.1.0 | db-client | High-performance JDBC connection pooling |
| joda-money | 0.12 | validation | Monetary value representation and arithmetic |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
