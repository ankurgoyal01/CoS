---
service: "Deal-Estate"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Deal Commerce"
platform: "Continuum"
team: "Deal Estate (nsanjeevi, sfint-dev@groupon.com)"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.2.10"
  framework: "Rails"
  framework_version: "3.2.22.5"
  runtime: "Unicorn"
  runtime_version: ""
  build_tool: "Bundler"
  package_manager: "Bundler/RubyGems"
---

# Deal-Estate Overview

## Purpose

Deal-Estate is the authoritative service for deal lifecycle management within Groupon's Continuum platform. It owns deal creation, modification, scheduling, distribution-window management, and state transitions from draft through publication and archival. The service acts as the central coordinator between merchant data from Salesforce, product data from Deal Catalog, and operational deal records consumed by downstream commerce systems.

## Scope

### In scope

- Creating and updating deal records via REST API
- Importing deals from external sources (e.g., `/deals/:id/import`)
- Scheduling and unscheduling deals for publication
- Managing distribution windows per deal
- Closing, unpausing, and archiving deals
- Searching and listing deals
- Syncing deal state from Deal Catalog events
- Syncing merchant and opportunity data from Salesforce events
- Syncing custom field data
- Publishing `dealEstate.option.create` and `option.import.status` events
- Background processing of deal-related tasks via Resque workers
- Scheduling recurring and delayed jobs via Resque Scheduler

### Out of scope

- Consumer-facing deal display and rendering (handled by downstream presentation services)
- Voucher generation (handled by `continuumVoucherInventoryService`)
- Taxonomy definition and management (handled by `continuumTaxonomyService`)
- Order processing and payment (handled by `continuumOrdersService`)
- Image hosting and transformation (handled by `grouponImagesService` — not in federated model)
- Merchant-of-record management (handled by `m3Service` — not in federated model)

## Domain Context

- **Business domain**: Deal Commerce
- **Platform**: Continuum
- **Upstream consumers**: Internal tooling, deal management UIs, downstream commerce services consuming published deal events
- **Downstream dependencies**: Deal Catalog, Deal Management API, Salesforce, Taxonomy, Voucher Inventory, Custom Fields, Orders, Groupon API, Geo Places

## Stakeholders

| Role | Description |
|------|-------------|
| Deal Estate Team | Service owners — nsanjeevi, sfint-dev@groupon.com |
| Merchant Operations | Uses deal scheduling and distribution workflows |
| Commerce Platform | Consumes deal lifecycle events and state |
| Salesforce Integration | Source of truth for merchant and opportunity data fed into deals |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.2.10 | Summary inventory |
| Framework | Rails | 3.2.22.5 | Summary inventory |
| Runtime | Unicorn | — | Summary inventory |
| Build tool | Bundler | — | Gemfile |
| Package manager | RubyGems / Bundler | — | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| httparty | 1.3.1 | http-framework | HTTP client for outbound REST calls to dependencies |
| resque | 1.27.4 | scheduling | Background job processing queue backed by Redis |
| resque-scheduler | 4.3.0 | scheduling | Delayed and recurring job scheduling on top of Resque |
| redis | 3.3.1 | db-client | Redis client for cache, locks, and job queue backend |
| state_machine | 1.1.2 | state-management | Manages deal lifecycle state transitions |
| paper_trail | — | logging | Audit trail / versioning of ActiveRecord model changes |
| service-client | 2.0.16 | http-framework | Groupon internal service client for inter-service HTTP calls |
| messagebus | 0.2.15 | message-client | Publishes and consumes async events on the Groupon message bus |
| sonoma-metrics | — | metrics | Emits service-level operational metrics |
| dalli | 2.7.6 | db-client | Memcached client for application cache |
| rollout | 2.0.1 | state-management | Redis-backed feature flag management |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
