---
service: "merchant-lifecycle-service"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Merchant Experience"
platform: "Continuum"
team: "MX JTier"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.1"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Merchant Lifecycle Service (MLS RIN) Overview

## Purpose

The Merchant Lifecycle Service (MLS RIN) is the central read and analytics layer for Groupon's merchant-facing data plane. It aggregates unit search results, maintains a deal index snapshot from the Continuum deal catalog, tracks inventory state changes via its Sentinel Kafka worker, and surfaces merchant insights (analytics, CX health) to internal and merchant-facing consumers. The service exists to decouple expensive cross-service aggregation from transactional write paths, providing a performant, pre-materialized view of deal and inventory state.

## Scope

### In scope
- Unit search and inventory query aggregation (`POST /units/v1/search`, `GET /units/v1/find/{isid}/{uuid}`)
- Deal index snapshot maintenance driven by catalog events
- Merchant analytics and CX health insights (`GET /insights/merchant/{uuid}/analytics`, `GET /insights/merchant/{uuid}/cxhealth`)
- CLO transaction reporting (`GET /clo/transactions`)
- History event retrieval (`GET /history`)
- Unit counts (`GET /units/v1/counts`)
- Kafka event consumption (deal catalog events, inventory update events)
- Kafka event publication (`DealSnapshotUpdated`, `InventoryProductIndexed`)
- Merchant risk threshold evaluation

### Out of scope
- Transactional deal writes (owned by Deal Catalog Service)
- Inventory mutation (owned by VIS / FIS)
- Merchant account management (owned by M3 Merchant Service)
- Order fulfillment (owned by Orders Service)
- Pricing rule authoring (owned by Pricing Service)

## Domain Context

- **Business domain**: Merchant Experience
- **Platform**: Continuum
- **Upstream consumers**: Merchant-facing portals, internal tooling, Merchant Advisor, Marketing Analytics
- **Downstream dependencies**: FIS (TPIS/Goods/Voucher), Deal Catalog Service, Marketing Analytics, VIS, GLive, Bhuvan, M3, UGC, Orders, Pricing, Merchant Advisor, Kafka/MBus

## Stakeholders

| Role | Description |
|------|-------------|
| MX JTier Team | Owns and maintains the service |
| Merchant Experience Platform | Consumers of analytics and insights APIs |
| Continuum Platform Teams | Producers of deal catalog and inventory events |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | pom.xml `java.version` |
| Framework | Dropwizard / JTier | 5.14.1 | pom.xml `jtier.version` |
| Runtime | JVM | 17 | pom.xml `java.version` |
| Build tool | Maven | — | pom.xml |
| Package manager | Maven | — | pom.xml |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-bundle-auth | 5.14.1 | auth | JTier-managed authentication/authorization |
| jtier-bundle-daas-postgres | 5.14.1 | db-client | Managed PostgreSQL connection pooling and JDBI integration |
| jtier-bundle-rxjava3 | 5.14.1 | scheduling | RxJava 3 integration for reactive async flows |
| jtier-bundle-retrofit | 5.14.1 | http-framework | Managed Retrofit HTTP client configuration |
| jtier-bundle-hk2 | 5.14.1 | http-framework | HK2 dependency injection container |
| fis-client | 0.6.6 | http-framework | FIS (Federated Inventory Service) client for TPIS/Goods/Voucher queries |
| mls-commons | 2.1.10 | http-framework | Shared MLS domain models and utilities |
| kafka-clients | 0.9.0.1 | message-client | Apache Kafka producer and consumer client |
| JDBI 3 | 3.x | db-client | SQL query mapping over JDBC for PostgreSQL DAOs |
| RxJava 3 | 3.x | scheduling | Reactive programming for async service orchestration |
| OpsLog | 1.0.3 | logging | Operational structured logging |
| Swagger Codegen | 3.0.25 | http-framework | Generated API client stubs from OpenAPI specs |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
