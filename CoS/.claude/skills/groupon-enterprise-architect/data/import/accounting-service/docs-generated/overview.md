---
service: "accounting-service"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Finance / Accounting"
platform: "Continuum"
team: "Finance Engineering (fed@groupon.com)"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.6.10"
  framework: "Rails"
  framework_version: "4.1.16"
  runtime: "Ruby"
  runtime_version: "2.6.10"
  build_tool: "Bundler"
  package_manager: "Bundler 1.17.3"
---

# Accounting Service Overview

## Purpose

Accounting Service is the central finance processing engine for Groupon's Continuum platform. It imports merchant contracts from Salesforce, ingests voucher and inventory events from upstream services, and drives the full lifecycle of invoices, merchant payments, and financial statements. The service operates under SOX compliance controls and requires GPROD approval for production changes.

## Scope

### In scope

- Importing and versioning merchant contracts from Salesforce
- Ingesting voucher, inventory, and order events into accounting models
- Generating and managing invoices (creation, approval, rejection, resubmission)
- Processing merchant payment runs and tracking payment status
- Producing financial statements and transaction records
- Providing vendor/merchant earnings and transaction query APIs
- Scheduled reconciliation and reporting jobs
- Background job processing via Resque and Delayed Job

### Out of scope

- Payment gateway processing and card-network communication (handled by payment processors)
- Deal and product catalog management (handled by `continuumDealCatalogService`)
- Order capture and refund processing (handled by `continuumOrdersService`)
- Voucher inventory lifecycle (handled by `continuumVoucherInventoryService`)
- General ledger accounting system (NetSuite — external integration, stub only)

## Domain Context

- **Business domain**: Finance / Accounting
- **Platform**: Continuum
- **Upstream consumers**: Internal services and operational tooling that query vendor contracts, transactions, invoices, and statements via REST APIs
- **Downstream dependencies**: `salesForce` (contract import), `continuumDealCatalogService` (deal metadata), `continuumOrdersService` (order and refund data), `continuumVoucherInventoryService` (voucher state), `messageBus` (event publishing and consumption), `continuumAccountingMysql` (primary data store), `continuumAccountingRedis` (queuing and cache)

## Stakeholders

| Role | Description |
|------|-------------|
| Finance Engineering | Service owner team; contact fed@groupon.com |
| SOX Compliance | Service is in-scope for SOX; production changes require GPROD approval |
| Merchant Payments Team | Primary internal consumer of payment and invoice APIs |
| Finance Operations | Consumers of statements, reconciliation exports, and reporting jobs |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.6.10 | `.ruby-version`, `Gemfile` |
| Framework | Rails | 4.1.16 | `Gemfile` |
| Runtime | Ruby | 2.6.10 | `.ruby-version` |
| Build tool | Bundler | 1.17.3 | `Gemfile.lock` |
| Package manager | Bundler | | `Gemfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `rails` | 4.1.16 | http-framework | Core web framework and ORM base |
| `mysql2` | 0.3.21 | db-client | MySQL adapter for ActiveRecord |
| `resque` | 2.7.0 | scheduling | Redis-backed background job processing |
| `delayed_job` | 4.1.11 | scheduling | ActiveRecord-backed deferred job execution |
| `messagebus` | 0.2.23 | message-client | Groupon Message Bus publish/consume client |
| `dalli` | 3.2.8 | db-client | Memcache/Redis cache client |
| `ar-octopus` | 0.9.2 | orm | Database sharding and read/write splitting for ActiveRecord |
| `rabl` | 0.16.1 | serialization | Ruby API Builder Language for JSON/XML response templating |
| `money` | 6.19.0 | validation | Currency-aware monetary value handling |
| `papertrail` | 7.1.3 | logging | ActiveRecord model versioning and audit trail |
| `lograge` | — | logging | Structured single-line Rails request logging |
| `coverband` | 5.2.5 | metrics | Production code usage and coverage tracking |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
