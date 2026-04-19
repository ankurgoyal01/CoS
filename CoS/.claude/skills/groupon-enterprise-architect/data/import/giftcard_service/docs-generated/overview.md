---
service: "giftcard_service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Payments"
platform: "Continuum"
team: "Payments"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.3.4"
  framework: "Rails"
  framework_version: "3.2.22"
  runtime: "Unicorn"
  runtime_version: "4.3.1"
  build_tool: "Rake"
  package_manager: "Bundler"
---

# Giftcard Service Overview

## Purpose

The Giftcard Service is a Rails-based payments microservice that handles gift card redemption for Groupon customers. It was extracted from the PWA frontend and integrates with the Orders bucks API and Lazlo to convert gift card balances into Groupon Bucks allocations. The service supports two distinct gift card types: external physical cards processed through First Data/Datawire, and internal Groupon VIS (Voucher Inventory Service) codes.

## Scope

### In scope
- Redeeming external gift cards via First Data/Datawire XML API
- Redeeming internal Groupon gift card codes (VIS codes prefixed `vs-`) via the Voucher Inventory Service
- Authorizing legacy Groupon credit codes without a PIN
- Creating legacy credit codes for campaigns
- Allocating Groupon Bucks to a user account via the Orders bucks API
- Currency mapping by country code for multi-region support
- Enforcing per-user redemption limits (ES and FR regions)
- Calculating and applying expiry dates for internal gift cards by country
- Service discovery for First Data endpoint URLs (background job, runs hourly)

### Out of scope
- Gift card issuance or purchase flows
- Bucks balance management (owned by Orders service)
- Voucher unit lifecycle management (owned by Voucher Inventory Service)
- Deal catalog management (owned by Deal Catalog Service)
- Payment processing beyond gift card redemption

## Domain Context

- **Business domain**: Payments
- **Platform**: Continuum
- **Upstream consumers**: PWA frontend, checkout flows, internal campaign tools
- **Downstream dependencies**: Orders Service (bucks allocations and unit status), Voucher Inventory Service (VIS code validation and redemption), Deal Catalog Service (product category validation), First Data/Datawire (external gift card processing)

## Stakeholders

| Role | Description |
|------|-------------|
| Team | Payments (cap-payments@groupon.com) |
| Owner | khsingh |
| Team Lead | pnamdeo |
| SRE Alerts | giftcard-service-alerts@groupon.com |
| PagerDuty | https://groupon.pagerduty.com/services/P5AMT2O |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.3.4 | `.ruby-version` |
| Framework | Rails | 3.2.22 | `Gemfile` |
| Runtime | Unicorn | 4.3.1 | `Gemfile` |
| Build tool | Rake | 0.9.2.2 | `Gemfile` |
| Package manager | Bundler | — | `Gemfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `rails` | 3.2.22 | http-framework | Web application framework |
| `unicorn` | 4.3.1 | http-framework | Ruby HTTP server for production |
| `typhoeus` | 1.1.2 | http-client | HTTP client for outbound calls to Orders, VIS, Deal Catalog, and First Data |
| `mysql2` | 0.3.18 | db-client | MySQL database adapter |
| `activerecord` | 3.2.22 | orm | ORM for LegacyCreditCode and FirstDataRegistration tables |
| `nokogiri` | 1.6.5 | serialization | Parses First Data XML responses; builds First Data ping XML |
| `sonoma-logger` | 1.0.6 | logging | Structured JSON logging (Sonoma platform) |
| `sonoma-metrics` | — | metrics | Metrics middleware integration |
| `sucker_punch` | 2.0.2 | scheduling | Background job queue for ServiceDiscovery job |
| `concurrent-ruby` | 1.0.5 | scheduling | Concurrent futures for parallel First Data URL pinging |
| `uuidtools` | 2.1.3 | validation | UUID generation for request IDs |
| `phone_home` | 0.0.1 | metrics | Internal Groupon service reporting |
| `rspec` | 3.6.0 | testing | Unit and integration test framework |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
