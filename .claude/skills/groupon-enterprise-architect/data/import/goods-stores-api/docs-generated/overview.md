---
service: "goods-stores-api"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Goods / Commerce"
platform: "Continuum"
team: "Goods CIM Engineering (sox-inscope)"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.5.9"
  framework: "Rails / Grape"
  framework_version: "4.2.11 / 0.19.2"
  runtime: "Puma"
  runtime_version: "6.3.1"
  build_tool: "Bundler"
  package_manager: "Bundler / RubyGems"
---

# Goods Stores API Overview

## Purpose

Goods Stores API is the authoritative REST API for managing goods products, options, merchants, contracts, and attachments within the Groupon Continuum platform. It serves GPAPI clients and internal tools by providing versioned endpoints (v1-v3) for the full lifecycle of physical goods commerce data. The service is complemented by a Resque-based worker pool for async post-processing and a Message Bus consumer that reacts to market data and pricing change events.

## Scope

### In scope

- CRUD management of goods products, options, merchants, and contracts
- Attachment and image upload handling (backed by S3 via CarrierWave/Attachinary)
- Elasticsearch-powered product and agreement search
- Authorization, token parsing, and role-based access control for all API requests
- Background post-processing pipelines for product state, inventory, fulfillment, and merchant attributes
- Contract lifecycle scheduling (start/end region-aware transitions)
- Elasticsearch indexing and re-indexing of goods records
- Batch import/export and backfill jobs (CSV/SFTP, DMAPI sync, feature flags, HTS mappings)
- Consumption of marketData and pricing JMS topics and enqueuing of downstream processing
- Event publishing for merchants, products, deals, inventory, price bands, and incentives

### Out of scope

- Deal catalog publishing logic (owned by `continuumDealCatalogService`)
- Pricing calculation (owned by `continuumPricingService`)
- Taxonomy definition and management (owned by `continuumTaxonomyService`)
- Order fulfillment and order lifecycle (owned by `continuumOrdersService`)
- Inventory availability tracking (owned by `continuumGoodsInventoryService`)
- Tax rate calculation (owned by `continuumAvalaraService`)
- Geographic place resolution (owned by `continuumBhuvanService` and `continuumM3PlacesService`)

## Domain Context

- **Business domain**: Goods / Commerce
- **Platform**: Continuum
- **Upstream consumers**: GPAPI clients, Deal Management tooling, internal merchant-facing UIs
- **Downstream dependencies**: Deal Catalog, Pricing, Taxonomy, Orders, Deal Management API, Bhuvan, M3 Places, Goods Inventory, Users, Avalara Tax API, Message Bus

## Stakeholders

| Role | Description |
|------|-------------|
| Goods CIM Engineering | Owning team; responsible for development, operations, and SOX compliance |
| Merchant-facing product teams | Consumers of v2/v3 API endpoints for product and contract management |
| Deal Management teams | Consumers of contract and deal lifecycle endpoints |
| SOX compliance | Service is in-scope for SOX; audit trail maintained via Paper Trail |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.5.9 | Gemfile / .ruby-version |
| Framework | Rails | 4.2.11 | Gemfile |
| API Framework | Grape | 0.19.2 | Gemfile |
| Runtime | Puma | 6.3.1 | Gemfile |
| Build tool | Bundler | - | Gemfile.lock |
| Package manager | RubyGems / Bundler | - | Gemfile |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Resque | 2.6.0 | scheduling | Background job queue backed by Redis |
| Elasticsearch | 7.17.11 | db-client | Product and agreement search index client |
| MessageBus | 0.5.3 | message-client | JMS/STOMP consumer for market data and pricing topics |
| Redis | 5.1.0 | db-client | Resque queues, caching, throttling, and batch state |
| CarrierWave | 1.3.4 | serialization | Attachment and image upload handling |
| Paper Trail | 10.3.1 | logging | Audit history for SOX-in-scope models |
| schema_driven_client | 0.5.1 | http-framework | Typed HTTP client for internal Groupon service calls |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
