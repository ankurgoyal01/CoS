---
service: "dynamic_pricing"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Dynamic Pricing"
platform: "Continuum"
team: "Dynamic Pricing (hijain)"
status: active
tech_stack:
  language: "Java"
  language_version: "8"
  framework: "RESTEasy"
  framework_version: ""
  runtime: "JVM / Jetty"
  runtime_version: ""
  build_tool: "Maven"
  package_manager: "Maven"
---

# Pricing Service Overview

## Purpose

The Pricing Service manages the full lifecycle of prices within Groupon's Continuum platform. It handles retail prices, program prices, and price rules for products, persists price history for audit and established-price calculations, and publishes pricing events to downstream consumers via the MBus message broker. The service acts as the authoritative source of current and future pricing state across the commerce engine.

## Scope

### In scope

- Creating, updating, and retrieving retail prices for products
- Bulk creation and validation of program prices
- Price rule management (CRUD, reservation, rule-based price application)
- Scheduled price updates via Quartz jobs and background workers
- Price history storage, retrieval, and established-price computation
- Redis-backed low-latency current price lookups (PriceSummary cache)
- Publishing price change events to MBus topics consumed by downstream services
- Consuming inventory update events from VIS to keep pricing in parity
- Product feature flag management for pricing enablement

### Out of scope

- Voucher inventory lifecycle (owned by `continuumVoucherInventoryService`)
- Deal catalog metadata management (owned by `continuumDealCatalogService`)
- Order processing and payment flows
- Consumer-facing storefront rendering

## Domain Context

- **Business domain**: Dynamic Pricing
- **Platform**: Continuum
- **Upstream consumers**: API proxy (`apiProxy`), internal Continuum services calling pricing endpoints via NGINX
- **Downstream dependencies**: `continuumVoucherInventoryService` (inventory validation), `continuumDealCatalogService` (deal metadata), `continuumMbusBroker` (event distribution)

## Stakeholders

| Role | Description |
|------|-------------|
| Team | Dynamic Pricing — hijain (service owner) |
| Consumers | Continuum services and APIs that read current/program prices |
| Operations | On-call engineers managing price update reliability and Redis cache health |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 8 | architecture models.dsl |
| Framework | RESTEasy | — | continuum-pricing-service-components.dsl |
| Runtime | JVM / Jetty | — | continuum-pricing-service-components.dsl |
| Build tool | Maven | — | service summary |
| Package manager | Maven | — | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| RESTEasy | — | http-framework | REST endpoint serving via Jetty |
| JDBC | — | db-client | Relational access to MySQL pricing and PWA schemas |
| Lettuce | — | db-client | Redis client for PriceSummary cache operations |
| JMS / HornetQ/ActiveMQ | — | message-client | MBus publish and consume for price events |
| Quartz | — | scheduling | Scheduled price update jobs and event emission |
| Apache HttpClient | — | http-framework | Outbound HTTP calls to VIS and Deal Catalog |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
