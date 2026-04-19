---
service: "deckard"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Commerce / My Groupons"
platform: "Continuum"
team: "Groupon API Team"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Lazlo (Vert.x)"
  framework_version: "4.0.29"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Deckard Overview

## Purpose

Deckard is an inventory aggregation service that indexes a consumer's purchased inventory units across all Groupon inventory systems (getaways, goods, vis, glive, tpis, mrgetaways, clo). It serves as the single intermediary providing consistent pagination, filtering, and sorting over the unioned, heterogeneous set of items displayed on the My Groupons page. The service caches inventory unit metadata per consumer in Redis, kept fresh both synchronously on request and asynchronously via message bus events.

## Scope

### In scope

- Aggregating inventory units for a given consumer across all Groupon inventory services
- Filtering inventory units by boolean fields (`available`, `redeemed`, `expired`, `gifted_to`, `gifted_by`, `retained_value`, `refunded`) and string fields (`inventory_service`)
- Sorting inventory units by `inventory_service_id`, `expires_at`, and `purchased_at`
- Paginating the unified result set with `offset` and `limit` parameters
- Caching consumer inventory indexes in Redis (application cache cluster)
- Handling async cache refreshes via a Redis-backed update queue
- Consuming message bus events to keep the cache current without waiting for a consumer request

### Out of scope

- Decorating inventory units with display data (handled by API Lazlo and decoration services such as Mentos and M3)
- Serving the My Groupons page UI directly (handled by iTier and Mobile front-end systems)
- Order management or purchase processing (handled by the Orders service)
- Individual inventory service business logic (handled by getaways, goods, vis, glive, tpis, mrgetaways, clo inventory services)

## Domain Context

- **Business domain**: Commerce / My Groupons (consumer purchase history)
- **Platform**: Continuum
- **Upstream consumers**: `continuumApiLazloService` (API Lazlo — the sole direct caller)
- **Downstream dependencies**: Inventory services (getaways, mrgetaways, glive, goods, clo, vis, tpis), Mentos decoration service, M3 decoration service, Groupon Message Bus (mbus), Redis cache cluster, Redis async update queue

## Stakeholders

| Role | Description |
|------|-------------|
| Groupon API Team | Service owner and primary developer |
| API Lazlo Team | Primary upstream consumer; decorates Deckard results for front-end display |
| My Groupons / Unity Team | Defines product requirements for the My Groupons page |
| Inventory Service Teams | Own the individual services Deckard aggregates |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `.java-version`, `pom.xml` (`api-parent-pom` 4.0.12) |
| Framework | Lazlo (Vert.x) | 4.0.29 (`lazlo-core`) | `pom.xml` `<lazlo-core.version>` |
| Runtime | JVM | 11 | `Dockerfile` `FROM docker.groupondev.com/jtier/prod-java11:3` |
| Build tool | Maven | 3 | `pom.xml` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `lazlo-all` (Lazlo framework) | 4.0.29 | http-framework | Core Vert.x-based service framework for controllers, clients, and BLS verticles |
| `api-lazlo-commons` | 4.0.0.2025.10.07 | http-framework | Shared API Lazlo utilities, filters, and inventory client abstractions |
| `inventory-client` | 4.0.0.2025.10.07 | db-client | Typed clients for all Groupon inventory services (getaways, goods, vis, etc.) |
| `mbus-client` | 1.5.0 | message-client | Groupon Message Bus STOMP client for consuming inventory and order events |
| `vertx-redis-client` | (vertx.version) | db-client | Vert.x Redis client for cache cluster interaction |
| `lettuce-core` | 6.0.0.M1 | db-client | Java Redis client (Lettuce) for async Redis operations |
| `promise` | 0.12.0 | scheduling | Groupon promise/async composition library for Vert.x event loop |
| `antlr4-runtime` | 4.5 | validation | ANTLR4 runtime for parsing the custom filter expression grammar |
| `metrics-vertx` | 3.0.12 | metrics | Groupon Vert.x metrics integration (InfluxDB/Telegraf) |
| `logback-classic` | 1.2.3 | logging | SLF4J logging backend |
| `jolokia-jvm` | 1.6.1 | metrics | JVM JMX-to-HTTP agent for Telegraf/Jolokia metrics scraping |
| `common-utils` | 2.0.1 | validation | Groupon shared API utility functions |
| `httpcore` | 4.4.10 | http-framework | Apache HTTP core for outbound HTTP client support |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
