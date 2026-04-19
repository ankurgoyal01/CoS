---
service: "orders-rails3"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Order Management"
platform: "Continuum"
team: "Orders Team (sox-inscope)"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.4.6"
  framework: "Rails"
  framework_version: "3.2.22.5"
  runtime: "Unicorn"
  runtime_version: "6.1.0"
  build_tool: "Bundler"
  package_manager: "RubyGems"
---

# orders-rails3 Overview

## Purpose

orders-rails3 is the core order processing service for the Continuum commerce platform. It handles the full order lifecycle — from initial placement and payment collection through inventory fulfillment, fraud review, refunds, and GDPR account redaction. The service is SOX in-scope, reflecting its direct role in financial transaction processing and customer data stewardship.

## Scope

### In scope

- Order creation, validation, and state management
- Payment authorization, capture, and collection via multiple gateways (GlobalPayments, Killbill, Adyen)
- Inventory unit reservation and voucher fulfillment
- Fraud screening via Accertify and Fraud Arbiter service
- Refund processing and order cancellations
- Tax account management for merchant tax flows
- Account redaction and anonymization (GDPR compliance)
- Publishing order lifecycle events to Message Bus (OrderSnapshots, Transactions, InventoryUnits.StatusChanged, TransactionalLedgerEvents, BillingRecordUpdate)
- Scheduled retry and maintenance operations via daemons

### Out of scope

- Deal catalog management (owned by `continuumDealCatalogService`)
- Voucher inventory allocation (owned by `continuumVoucherInventoryService`)
- Payment gateway account management (owned by `continuumPaymentsService`)
- User account management (owned by `continuumUsersService`)
- Merchant and place data management (owned by `continuumM3MerchantService`, `continuumM3PlacesService`)
- Analytics reporting (data extracted to `continuumAnalyticsWarehouse`, consumed externally)

## Domain Context

- **Business domain**: Order Management
- **Platform**: Continuum
- **Upstream consumers**: Storefront, mobile clients, and internal services that create and manage orders via the Orders REST API
- **Downstream dependencies**: Users Service, Deal Catalog Service, Voucher Inventory Service, Payments Service, Fraud Arbiter Service, Incentives Service, Geo/GeoDetails Services, Taxonomy Service, M3 Merchant Service, M3 Places Service, Payment Gateways (GlobalPayments/Killbill/Adyen), Message Bus

## Stakeholders

| Role | Description |
|------|-------------|
| Orders Team | Primary owners; responsible for development, on-call, and SOX compliance |
| Finance / Accounting | Depend on TransactionalLedgerEvents and BillingRecordUpdate for financial reconciliation |
| Fraud & Risk | Consume fraud review decisions and fraud DB data |
| Compliance / Legal | Depend on account redaction flows for GDPR obligations |
| Analytics | Consume data written to the Analytics Warehouse |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.4.6 | Gemfile / .ruby-version |
| Framework | Rails | 3.2.22.5 | Gemfile |
| Runtime | Unicorn | 6.1.0 | Gemfile |
| Build tool | Bundler | — | Gemfile.lock |
| Package manager | RubyGems | — | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| resque | 1.20.0 | scheduling | Background job queue backed by Redis |
| redis | 2.2.2 | db-client | Redis client for caching, locking, and Resque queues |
| mysql2 | 0.3.21 | db-client | MySQL/PostgreSQL database adapter for ActiveRecord |
| messagebus | 0.2.2 | message-client | Message Bus client for publishing async order events |
| savon | 2.2.0 | http-framework | SOAP client (used for legacy payment/merchant integrations) |
| typhoeus | 0.6.5 | http-framework | Parallel HTTP client for outbound REST calls |
| service-client | 2.0.13 | http-framework | Groupon internal HTTP service client (ServiceRequestFactory) |
| sonoma-metrics | 0.9.0 | metrics | Internal metrics instrumentation (StatsD/Sonoma) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
