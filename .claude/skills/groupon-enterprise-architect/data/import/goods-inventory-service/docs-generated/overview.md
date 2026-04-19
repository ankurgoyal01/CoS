---
service: "goods-inventory-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Commerce / Inventory & Fulfillment"
platform: "Continuum"
team: "Universal Checkout"
status: active
tech_stack:
  language: "Java"
  framework: "Play Framework"
  runtime: "JVM"
  build_tool: "SBT"
---

# Goods Inventory Service Overview

## Purpose

Goods Inventory Service (GIS) is the central inventory management backend for Groupon's universal checkout flow. It tracks product availability, manages inventory reservations during the purchase lifecycle, orchestrates order fulfillment, and handles reverse fulfillment operations such as cancellations and returns. The service acts as the authoritative source for inventory unit state across the goods commerce pipeline, bridging upstream inventory management systems with downstream order fulfillment and shipping services.

## Scope

### In scope

- Inventory product and inventory unit lifecycle management
- Real-time product availability checks and inventory projections
- Reservation creation, confirmation, and expiration during checkout
- Order fulfillment coordination with ORC and SRS
- Reverse fulfillment and cancellation processing
- Vendor tax configuration and rate management
- Postal code and shipping option management
- Pricing integration and caching for inventory products
- Custom fields enrichment for products
- Localized message rules for inventory-related consumer messaging
- Inventory synchronization with upstream Inventory Management Service (IMS)
- Publishing inventory events to the message bus for downstream consumers
- Scheduled maintenance jobs (reservation cleanup, missed auth retry, exchange processing, charge-when-ship sync)

### Out of scope

- Deal creation and catalog management (handled by Deal Catalog / Deal Management services)
- Payment processing (handled by payment services; GIS triggers auth/capture via OrdersClient)
- Warehouse physical inventory operations (handled by IMS)
- Shipping label generation and carrier integration (handled by SRS Outbound Controller)
- Order routing decisions (handled by ORC Service)
- Consumer-facing storefront UI (handled by MBNXT and other frontend services)
- Merchant portal operations (handled by merchant-facing services)

## Domain Context

- **Business domain**: Commerce / Inventory & Fulfillment
- **Platform**: Continuum
- **Upstream consumers**: Checkout services, GPAPI, consumer-facing APIs that query product availability and create reservations
- **Downstream dependencies**: Goods Inventory Management Service (IMS), Goods Stores Service, GPAPI Service, SRS Outbound Controller, ORC Service, Item Master Service, Currency Conversion Service, Delivery Estimator Service

## Stakeholders

| Role | Description |
|------|-------------|
| Universal Checkout team | Primary engineering owners responsible for development and operations |
| Goods Commerce team | Cross-functional team overseeing the goods commerce pipeline end-to-end |
| Merchant Operations | Stakeholders who depend on accurate inventory and fulfillment state |
| Consumer Experience | Teams relying on real-time availability and delivery estimates |

## Tech Stack

### Core

| Layer | Technology | Evidence |
|-------|-----------|----------|
| Language | Java | DSL: "Java, Play Framework" |
| Framework | Play Framework | DSL: container technology declaration |
| Runtime | JVM | Inferred from Java + Play |
| Build tool | SBT | Standard for Play Framework projects |

### Key Libraries

| Library | Category | Purpose |
|---------|----------|---------|
| Play Framework | http-framework | HTTP routing, controller lifecycle, async request handling |
| JDBI | db-client | Data access layer for PostgreSQL repositories |
| Redis (Jedis/Lettuce) | db-client | Cache client for GCP Memorystore Redis |
| Groupon MessageBus SDK | message-client | Publishing and consuming inventory and order events |
| Play WS | http-framework | HTTP client for outbound REST calls to external services |
| Quartz Scheduler | scheduling | Cron-based job scheduling for maintenance and background tasks |
| Logback / StenoLogger | logging | Structured logging and diagnostics |
| Jackson | serialization | JSON serialization for API models and DTOs |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
