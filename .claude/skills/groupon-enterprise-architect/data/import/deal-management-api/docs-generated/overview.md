---
service: "deal-management-api"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Deal Management"
platform: "Continuum"
team: "Deal Setup Product (dms-dev)"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.2.3"
  framework: "Rails"
  framework_version: "4.2.6"
  runtime: "Puma / JRuby"
  runtime_version: "3.0 / 9.1.6.0"
  build_tool: "Bundler"
  package_manager: "RubyGems"
---

# Deal Management API (DMAPI) Overview

## Purpose

Deal Management API (DMAPI) is the authoritative REST service for creating, configuring, and managing the full lifecycle of Groupon deals within the Continuum commerce platform. It exposes versioned endpoints (v1-v3) that internal teams and tooling use to set up deal structures, trigger publish/unpublish/pause actions, manage approval workflows, and keep downstream systems such as Deal Catalog and Salesforce in sync. Background processing is handled by an accompanying Resque worker that executes async tasks including Salesforce synchronization and catalog updates.

## Scope

### In scope

- CRUD operations for deal records (create, read, update, delete)
- Deal lifecycle transitions: publish, unpublish, pause, approve
- Merchant and place data retrieval and association with deals
- Inventory product and pricing configuration for deals
- Contract data service integration and contract party management
- Write-request tracking and operation history logging
- Background async processing for Salesforce and Deal Catalog sync
- Rate limit management per API client (`/clients`)

### Out of scope

- Order processing and payment capture (owned by `continuumOrdersService`)
- Pricing rule calculation (owned by `continuumPricingService`)
- Taxonomy hierarchy management (owned by `continuumTaxonomyService`)
- Voucher/coupon redemption and fulfillment (owned by respective inventory services)
- Consumer-facing deal browsing and search (owned by MBNXT/frontend)

## Domain Context

- **Business domain**: Deal Management
- **Platform**: Continuum
- **Upstream consumers**: Internal deal setup tooling, merchant-facing portals, campaign management systems
- **Downstream dependencies**: Salesforce, Deal Catalog Service, Orders Service, Pricing Service, Taxonomy Service, Contract Data Service, Voucher/Coupons/Goods/ThirdParty/CLO Inventory Services, m3 (merchant/places)

## Stakeholders

| Role | Description |
|------|-------------|
| Deal Setup Product Team (dms-dev) | Owns and maintains the service |
| Merchant Operations | Uses DMAPI tooling to configure and publish deals |
| Commerce Engineering | Consumes deal data via downstream services |
| Salesforce Admins | Receive synced deal and merchant records from DMAPI |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby (MRI) | 2.2.3 | Inventory summary |
| Language (alt) | JRuby | 9.1.6.0 | Inventory summary |
| Framework | Rails | 4.2.6 | Inventory summary |
| Runtime (web) | Puma | 3.0 | Inventory summary |
| Runtime (worker) | Resque | 1.25.2 | Inventory summary |
| Build tool | Bundler | — | RubyGems ecosystem |
| Package manager | RubyGems | — | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Resque | 1.25.2 | scheduling | Background job processing via Redis queues |
| service-discovery-client | 2.2.1 | http-framework | Internal service discovery and routing |
| service-discovery-validations | 1.5.1 | validation | Validates service discovery configurations |
| steno_logger | 1.0 | logging | Structured JSON logging |
| sonoma-metrics | — | metrics | Application metrics emission |
| Typhoeus | 0.8 | http-framework | HTTP client (MRI runtime) |
| Manticore | 0.6.4 | http-framework | HTTP client (JRuby runtime, JVM-based) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
