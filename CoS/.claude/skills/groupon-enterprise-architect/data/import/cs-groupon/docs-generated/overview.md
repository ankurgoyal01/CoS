---
service: "cs-groupon"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Customer Service"
platform: "Continuum"
team: "GSO Engineering"
status: active
tech_stack:
  language: "Ruby"
  language_version: "1.9.3-p125"
  framework: "Rails"
  framework_version: "3.2.22"
  runtime: "Unicorn"
  runtime_version: "4.3.1"
  build_tool: "Bundler"
  package_manager: "Bundler (Gemfile)"
---

# cyclops (cs-groupon) Overview

## Purpose

cyclops is Groupon's internal Customer Service Management application, codenamed cs-groupon. It provides GSO Engineering's customer service teams with tooling to look up orders, manage refunds, resolve customer issues, and automate CS workflows. The service acts as an integration hub, aggregating data from Orders, Users, Deal Catalog, Inventory, Payment, and Voucher services to give CS agents a unified view of customer interactions.

## Scope

### In scope

- Customer issue lookup and resolution workflows
- Order and refund lookups via internal services
- User account lookups and profile management by CS agents
- Deal and inventory metadata retrieval for CS context
- Voucher operations (issue, cancel, resend)
- Background job processing for async CS tasks (bulk exports, retry queues)
- GDPR erasure request handling and confirmation event publishing
- Zendesk integration for ticket management
- Email notification dispatch to customers
- Elasticsearch-powered fuzzy search across CS records
- Session management for CS agent login/logout

### Out of scope

- Order placement and checkout (handled by `continuumOrdersService`)
- Payment processing logic (handled by killbill / `continuumPricingService`)
- Deal creation and campaign management (handled by `continuumDealCatalogService`)
- Consumer-facing storefront (handled by MBNXT / Encore)
- Merchant portal operations

## Domain Context

- **Business domain**: Customer Service
- **Platform**: Continuum
- **Upstream consumers**: Internal CS agents via browser (Web App), external CS tooling integrations (API)
- **Downstream dependencies**: `continuumOrdersService`, `continuumUsersService`, `continuumDealCatalogService`, `continuumInventoryService`, `continuumPricingService`, `continuumEmailService`, `continuumVoucherInventoryService`, `continuumGoodsInventoryService`, `continuumThirdPartyInventoryService`, `continuumCloInventoryService`, `continuumRegulatoryConsentLogApi`, `messageBus`, Zendesk

## Stakeholders

| Role | Description |
|------|-------------|
| GSO Engineering | Owning team; responsible for development, deployment, and maintenance |
| Customer Service Agents | Primary end-users of the Web App for issue resolution |
| Integration Consumers | Internal services consuming the `/api/v1`–`/api/v3` endpoints |
| Data Privacy / Legal | Consumers of GDPR erasure event `gdpr.account.v1.erased.complete` |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 1.9.3-p125 | Gemfile / inventory |
| Framework | Rails | 3.2.22 | Gemfile / inventory |
| Runtime | Unicorn | 4.3.1 | Gemfile / inventory |
| Build tool | Bundler | — | Gemfile.lock |
| Package manager | Bundler (Gemfile) | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| resque | 1.27.4 | scheduling | Background job queue backed by Redis |
| redis | 4.0.2 | db-client | Redis client for cache, queue, and sessions |
| mysql2 | — | db-client | MySQL adapter for ActiveRecord |
| messagebus | 0.5.2 | message-client | Async messaging (MBus) for event publish/consume |
| typhoeus | 0.6.3 | http-framework | Parallel HTTP client for downstream service calls |
| cancan | 1.6.5 | auth | Role-based authorization for CS agents |
| warden | 1.0.5 | auth | Authentication middleware |
| zendesk_api | — | integration | Zendesk ticket management client |
| sonoma-metrics | 0.9.0 | metrics | Internal metrics publishing to `metricsStack` |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
