---
service: "merchant-deal-management"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Deal Management / Merchant Commerce"
platform: "Continuum"
team: "Merchant Platform"
status: active
tech_stack:
  language: "Ruby"
  language_version: ""
  framework: "Ruby on Rails"
  framework_version: ""
  runtime: "Ruby"
  runtime_version: ""
  build_tool: "Bundler"
  package_manager: "Bundler/RubyGems"
---

# Merchant Deal Management Overview

## Purpose

The Merchant Deal Management service is Groupon's primary deal lifecycle write API within the Continuum platform. It receives deal creation, update, and status-change requests from internal tools and merchant-facing surfaces, validates and orchestrates those writes across a set of downstream Continuum services, and persists authoritative write-request state for auditing and history. An asynchronous Resque worker pool handles long-running write flows so that the HTTP API can return promptly while background processing continues.

## Scope

### In scope

- Receiving and validating synchronous deal management HTTP requests
- Orchestrating deal writes across catalog, pricing, inventory, merchant, taxonomy, and geo services
- Synchronizing deal and merchant data with Salesforce
- Scheduling and executing asynchronous write-request jobs via Resque
- Persisting write requests and history events in MySQL
- Rate-limiting inbound API calls using Redis
- Coordinating appointment-related deal updates with the Appointments Engine
- Emitting structured application logs and runtime metrics

### Out of scope

- Deal catalog reads and search (owned by `continuumDealCatalogService`)
- Order processing and fulfillment (owned by `continuumOrdersService`)
- Pricing rule definition (owned by `continuumPricingService`)
- Taxonomy hierarchy management (owned by `continuumTaxonomyService`)
- Merchant identity and profile storage (owned by `continuumM3MerchantService`)
- Inventory supply management (owned by voucher, goods, third-party, coupons, CLO inventory services)
- Contract data management (owned by `continuumContractDataService`)

## Domain Context

- **Business domain**: Deal Management / Merchant Commerce
- **Platform**: Continuum
- **Upstream consumers**: Internal deal management tooling, merchant-facing portals, and operator workflows that submit deal write requests via HTTP
- **Downstream dependencies**: `continuumDealCatalogService`, `continuumOrdersService`, `continuumPricingService`, `continuumTaxonomyService`, `continuumGeoService`, `continuumM3MerchantService`, `continuumM3PlacesService`, `continuumVoucherInventoryService`, `continuumThirdPartyInventoryService`, `continuumGoodsInventoryService`, `continuumCouponsInventoryService`, `continuumCloInventoryService`, `continuumAppointmentsEngine`, `continuumContractDataService`, Salesforce

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant Platform Team | Service owners responsible for deal write API development and operations |
| Merchant Operations | Internal users submitting deal creation and update workflows |
| Platform Engineering | Responsible for Continuum integration health and infrastructure |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | Not specified in repo | architecture DSL: "Ruby, Resque" |
| Framework | Ruby on Rails | Not specified in repo | architecture DSL: "Rails Controllers" |
| Runtime | Ruby | Not specified in repo | architecture DSL |
| Build tool | Bundler | Not specified in repo | Standard Rails tooling |
| Package manager | RubyGems / Bundler | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Rails Controllers | — | http-framework | Versioned REST endpoint handling |
| ActiveRecord | — | orm | MySQL persistence for write requests and history |
| Faraday | — | http-client | HTTP client used by Remote Client Gateway for downstream service calls |
| ServiceDiscoveryClient | — | service-discovery | Continuum service registry integration for downstream routing |
| Resque | — | scheduling | Background job queue backed by Redis |
| Redis | — | db-client | Queue depth tracking, rate limiting, and transient coordination state |
| HistoryLogger | — | logging | Write-request event logging and history record persistence |

> Tech stack versions are not resolvable from the available repository inventory (no package.json, go.mod, Gemfile, or pom.xml present). Version evidence above is derived solely from the architecture DSL.
