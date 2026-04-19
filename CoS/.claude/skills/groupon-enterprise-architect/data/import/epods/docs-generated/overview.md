---
service: "epods"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "3rd-Party Booking Integration"
platform: "Continuum"
team: "3PIP Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard / JTier"
  framework_version: "5.13.2"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# EPODS — Exchange Partner Order Data Service Overview

## Purpose

EPODS (Exchange Partner Order Data Service) is a translation layer between Groupon's commerce platform and third-party booking partners such as MindBody, Booker, Square, Shopify, HBW, BT, VIS, and PAMS. It normalizes partner-specific booking, availability, merchant, and product data into Groupon's internal domain model. EPODS is the authoritative integration point for all external partner booking flows within the Continuum platform.

## Scope

### In scope

- Translating booking create, cancel, and retrieval requests between Groupon consumers and external partner APIs
- Receiving and processing inbound webhooks from partners (e.g., MindBody, Square, Shopify) for booking and availability change notifications
- Synchronizing availability data from partner systems and publishing `AvailabilityUpdate` events
- Managing entity mappings between Groupon identifiers (deals, products, units, segments, merchants) and partner-system identifiers
- Publishing `VoucherRedemption` and `BookingStatusChange` events to downstream Groupon services
- Consuming `AvailabilityMessageHandler` and `VoucherMessageHandler` events from the internal message bus
- Providing read APIs for availability, merchant, product, segment, and unit data surfacing partner-translated records

### Out of scope

- Direct consumer-facing booking UI (handled by MBNXT / Booking Tool)
- Voucher lifecycle management beyond status change notification (handled by Orders and CFS)
- Partner onboarding configuration storage (handled by Partner Service and PAMS)
- Deal catalog ownership and deal data persistence (handled by Deal Catalog Service)

## Domain Context

- **Business domain**: 3rd-Party Booking Integration
- **Platform**: Continuum
- **Upstream consumers**: Booking Tool (`bookingToolService`), Orders (`continuumOrdersService`), and any Groupon service invoking booking or availability APIs
- **Downstream dependencies**: MindBody, Booker, Square, Shopify, HBW, BT, VIS, PAMS; internal: Deal Catalog, Calendar Service, CFS, Partner Service, Merchant API, Orders, Ingestion

## Stakeholders

| Role | Description |
|------|-------------|
| 3PIP Engineering | Owning team responsible for development, maintenance, and on-call |
| Partner Integrations | Business stakeholders managing third-party partner relationships |
| Commerce Platform | Consumers of booking and availability APIs within Continuum |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | Summary inventory |
| Framework | Dropwizard / JTier | 5.13.2 | Summary inventory |
| Runtime | JVM | 17 | Summary inventory |
| Build tool | Maven | — | Summary inventory |
| Package manager | Maven | — | pom.xml |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-daas-postgres | — | db-client | JTier-managed PostgreSQL data access layer |
| jtier-cache | 1.7.0 | db-client | Distributed cache integration via Redis |
| jtier-messagebus-client | — | message-client | JMS/STOMP message bus publish and consume |
| jtier-retrofit | — | http-framework | HTTP client for partner and internal REST APIs |
| jtier-quartz-bundle | — | scheduling | Quartz-based scheduled jobs for availability sync |
| jdbi3-core | 3.38.0 | orm | SQL query binding and result mapping over JDBC |
| failsafe | 2.3.1 | http-framework | Retry, circuit breaker, and fallback policies |
| jackson-dataformat-csv | — | serialization | CSV serialization for partner data import/export |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
