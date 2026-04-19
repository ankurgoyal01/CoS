---
service: "voucher-inventory-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Inventory / Supply"
platform: "Continuum"
team: "Voucher Inventory"
status: active
tech_stack:
  language: "JRuby"
  language_version: ""
  framework: "Ruby on Rails"
  framework_version: ""
  runtime: "JRuby on JVM"
  runtime_version: ""
  build_tool: "Bundler / Rake"
  package_manager: "Bundler"
---

# Voucher Inventory Service Overview

## Purpose

The Voucher Inventory Service (VIS) is the central inventory management system within Groupon's Continuum platform. It owns the full lifecycle of voucher inventory -- from product-level configuration (inventory products, consumer contracts, redemption policies) through unit-level operations (reservations, redemptions, gifting, refunds, expirations, and booking). VIS serves as the authoritative source of truth for all voucher inventory state and coordinates with numerous upstream and downstream services to keep the commerce pipeline consistent.

## Scope

### In scope
- Inventory product creation, configuration, and lifecycle management
- Consumer contract and redemption policy management
- Voucher unit reservation during checkout
- Voucher unit redemption, including barcode and third-party code pool flows
- Gifting, refund, and expiration processing for voucher units
- Reservation pricing validation and policy enforcement
- Redemption code pool management and upload workflows
- Sold count tracking and quantity summary aggregation
- Background reconciliation of unit status against the Orders service
- Backfill and batch data correction operations
- GDPR right-to-forget anonymization for voucher and order data
- Publishing domain events for inventory products, units, and redemptions
- Booking appointment coordination for voucher-linked bookings
- Daily analytical snapshot export to the Enterprise Data Warehouse (EDW)

### Out of scope
- Order creation and payment processing (handled by Orders service)
- Deal creation and creative content management (handled by Deal Catalog)
- Merchant and location master data (handled by Merchant Service)
- Dynamic pricing calculations (handled by Pricing Service)
- Physical goods shipping fulfillment (handled by Goods Central / Shipping Service)
- Geospatial location computations (handled by Geo Service)
- Feature flag and experiment evaluation logic (handled by Reading Rainbow)

## Domain Context

- **Business domain**: Inventory / Supply
- **Platform**: Continuum (Groupon's core commerce engine)
- **Upstream consumers**: Orders service, Deal Catalog, checkout flows, merchant tools, internal analytics consumers
- **Downstream dependencies**: Orders Service, Pricing Service, Deal Catalog Service, Merchant Service, JTier Service, Goods Central Service, Geo Service, Booking Appointments Service, Shipping Service, GDPR Service, Reading Rainbow, Enterprise Data Warehouse (EDW)

## Stakeholders

| Role | Description |
|------|-------------|
| Voucher Inventory Team | Owns and operates the service, manages inventory product configuration and unit lifecycle |
| Orders / Checkout Team | Depends on VIS for reservation creation during purchase flow |
| Merchant Operations | Uses VIS-powered tools for redemption and inventory visibility |
| Analytics / Data Engineering | Consumes EDW exports and domain events for reporting |
| GDPR / Compliance | Relies on VIS for PII anonymization in voucher data |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JRuby | -- | containers.dsl: "JRuby, Rails, Sidekiq" |
| Framework | Ruby on Rails | -- | containers.dsl: "JRuby, Rails, Sidekiq" |
| Runtime | JRuby on JVM | -- | containers.dsl |
| Build tool | Bundler / Rake | -- | Inferred from Rails convention |
| Package manager | Bundler | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Sidekiq | -- | scheduling | Background job processing for workers and async tasks |
| ActiveMessaging | -- | message-client | JMS/ActiveMQ message bus integration for event publishing and consumption |
| ActiveRecord | -- | orm | Database access layer for MySQL (products DB and units DB) |
| Redis client | -- | db-client | Caching, distributed locking, rate limiting, and Sidekiq queue backend |
| New Relic | -- | metrics | APM and performance monitoring |
| Wavefront | -- | metrics | Metrics collection and dashboarding |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
