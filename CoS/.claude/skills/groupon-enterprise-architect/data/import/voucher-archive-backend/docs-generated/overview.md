---
service: "voucher-archive-backend"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Financial Systems / E-Commerce"
platform: "continuum"
team: "LivingSocial Voucher Archive (livingsocial-voucher-archive@groupon.com)"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.2.3"
  framework: "Rails"
  framework_version: "4.2"
  runtime: "Ruby MRI / Puma"
  runtime_version: "2.2.3"
  build_tool: "Bundler"
  package_manager: "Bundler / RubyGems"
---

# Voucher Archive Backend Overview

## Purpose

The voucher-archive-backend (livingsocial-voucher-archive-backend) preserves and exposes legacy LivingSocial voucher data for use by consumers, merchants, and customer service representatives. It acts as the authoritative read/write API for archived LivingSocial voucher lifecycle operations — including retrieval, redemption, and refunds — within the Continuum commerce platform. It also handles GDPR right-to-erasure requests for LivingSocial account data.

## Scope

### In scope

- Consumer-facing voucher retrieval and display (including PDF and QR code generation)
- Merchant voucher redemption and bulk redemption workflows
- CSR-facing refund processing and coupon state management
- Deal and checkout data retrieval from legacy LivingSocial databases
- GDPR account erasure processing via message bus integration
- Authentication of consumers, merchants, and CSRs via token validation

### Out of scope

- New Groupon voucher issuance or order creation (handled by active commerce services)
- Merchant onboarding or account management
- Current Groupon deal catalog management (handled by Deal Catalog Service)
- User account creation or identity management (handled by Users Service)

## Domain Context

- **Business domain**: Financial Systems / E-Commerce
- **Platform**: Continuum
- **Upstream consumers**: Consumer mobile/web apps, Merchant portal, CSR tooling
- **Downstream dependencies**: Users Service, CS Token Service, MX Merchant API, City Service, Message Bus, Image Service, Deal Catalog Service, Retcon Service

## Stakeholders

| Role | Description |
|------|-------------|
| Consumer | End-user who purchased a LivingSocial voucher and needs to view or use it |
| Merchant | Business that accepts LivingSocial vouchers and performs redemptions |
| CSR (Customer Service Rep) | Internal Groupon agent who processes refunds and account queries |
| GDPR Compliance | Automated pipeline that triggers erasure of personal data on request |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.2.3 | Inventory / `.ruby-version` |
| Framework | Rails | 4.2 | Inventory / `Gemfile` |
| Runtime | Ruby MRI / Puma | 2.2.3 | Inventory |
| Build tool | Bundler | — | `Gemfile.lock` |
| Package manager | RubyGems / Bundler | — | `Gemfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| rails | 4.2 | http-framework | Web framework and routing |
| puma | — | http-framework | Multi-threaded application server |
| mysql2 | 0.3.18 | db-client | MySQL database adapter |
| aasm | 3.0.25 | state-management | Voucher/coupon state machine transitions |
| messagebus | — | message-client | JMS message bus publish/subscribe |
| rest-client | — | http-framework | HTTP client for downstream service calls |
| pdfkit | 0.7.0 | serialization | PDF voucher generation |
| rqrcode | 0.4.2 | serialization | QR code generation for vouchers |
| rom | 3.0 | orm | Ruby Object Mapper for data access |
| whenever | — | scheduling | Cron job scheduling |
| paranoia | — | orm | Soft-delete support for records |
| steno_logger | 1.0 | logging | Structured application logging |
| sonoma-metrics | 0.8.0 | metrics | Application metrics emission |
| rspec-rails | — | testing | RSpec test framework for Rails |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
