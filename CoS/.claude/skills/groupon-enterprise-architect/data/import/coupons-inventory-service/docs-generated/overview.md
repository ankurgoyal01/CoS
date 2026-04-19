---
service: "coupons-inventory-service"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Commerce / Coupon Inventory"
platform: "Continuum"
team: "Inventory Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "8+"
  framework: "Dropwizard (JTIER)"
  framework_version: "—"
  runtime: "Java"
  runtime_version: "8+"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Coupons Inventory Service Overview

## Purpose

Coupons Inventory Service is the coupon inventory management backend for Groupon's Continuum platform. It exposes REST APIs for managing the full lifecycle of coupon inventory products, units, reservations, clicks, and availability. The service orchestrates validation, persistence to Postgres, Redis caching, and asynchronous integration with the Deal Catalog and VoucherCloud services via the IS Core Message Bus.

## Scope

### In scope

- Creating, updating, and querying inventory products with localized content
- Managing coupon units associated with inventory products
- Creating and managing reservations against inventory
- Tracking click events for offers
- Exposing availability information for products and units
- Caching product data and deal-id lists in Redis for performance
- Publishing inventory product creation events to the IS Core Message Bus
- Consuming IS Core orders and GDPR-related messages
- Resolving deal identifiers from Deal Catalog for newly created inventory products
- Fetching unique redemption codes from VoucherCloud for reservations
- Client-based authentication and authorization for API access

### Out of scope

- Deal and product catalog management (handled by Deal Catalog Service)
- Order processing and fulfillment (handled by Orders Service)
- Voucher redemption and lifecycle (handled by Voucher Inventory Service)
- Payment processing (handled by payment services)
- Consumer-facing coupon browsing and display (handled by frontend applications)

## Domain Context

- **Business domain**: Commerce / Coupon Inventory
- **Platform**: Continuum
- **Upstream consumers**: Internal Continuum services that manage deals, orders, and voucher operations query this service for inventory product state, unit availability, and reservation management
- **Downstream dependencies**: `continuumCouponsInventoryDb` (Postgres primary store), `continuumCouponsInventoryRedis` (Redis cache), `continuumCouponsInventoryMessageBus` (IS Core Message Bus), Deal Catalog Service (deal-id resolution), VoucherCloud (redemption code retrieval)

## Stakeholders

| Role | Description |
|------|-------------|
| Inventory Engineering | Service owner team responsible for development and operations |
| Commerce Platform | Upstream platform team consuming inventory product and reservation APIs |
| Deal Operations | Teams managing deal lifecycle that depend on inventory product state |
| Merchant Operations | Teams that interact with coupon inventory for merchant deal management |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 8+ | Architecture DSL: `"Java, Dropwizard (JTIER), Jersey, Dagger"` |
| Framework | Dropwizard (JTIER) | — | Architecture DSL: container technology declaration |
| Runtime | Java | 8+ | Inferred from Dropwizard/JTIER conventions |
| Build tool | Maven | — | Inferred from JTIER conventions |
| Package manager | Maven | | Inferred from JTIER conventions |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Dropwizard | — | http-framework | RESTful HTTP framework providing embedded Jetty, Jersey, Jackson, and lifecycle management |
| Jersey (JAX-RS) | — | http-framework | REST resource implementation via JAX-RS annotations |
| Dagger | — | dependency-injection | Compile-time dependency injection for service wiring |
| Jdbi | — | orm | Lightweight SQL-object mapping for Postgres data access |
| Flyway | — | db-client | Database schema migration management |
| Jedis | — | db-client | Redis client for product and deal-id caching |
| OkHttp | — | http-framework | HTTP client for external service calls (Deal Catalog, VoucherCloud) |
| Mbus | — | message-client | Groupon Message Bus publish/consume client for async events |
| Dropwizard Auth | — | auth | Authentication and authorization filter framework |
| Dropwizard Metrics | — | metrics | Application metrics and health check infrastructure |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
