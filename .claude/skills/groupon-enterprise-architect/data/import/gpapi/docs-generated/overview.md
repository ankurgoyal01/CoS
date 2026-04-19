---
service: "gpapi"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Goods Platform / Vendor Integration"
platform: "continuum"
team: "Goods Platform"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.7.8"
  framework: "Rails"
  framework_version: "5.2.8"
  runtime: "Puma"
  runtime_version: "6.3.1"
  build_tool: "Bundler"
  package_manager: "Bundler 2.3.26"
---

# Goods Product API (gpapi) Overview

## Purpose

gpapi is the API proxy and orchestration layer for the Goods Vendor Portal on the Continuum platform. It centralizes vendor-facing operations for managing goods products, items, deals, merchants, contracts, and compliance workflows. The service acts as an intermediary between the Vendor Portal UI and a set of downstream Continuum microservices, translating vendor portal requests into coordinated calls across the Goods ecosystem.

## Scope

### In scope

- Vendor onboarding and user-vendor account linking
- Product and item lifecycle management (create, update, approve, deactivate)
- Item master management including vendor pricing and item attributes
- Contract and co-op agreement creation and lifecycle tracking
- Promotion and deal management (promotions, deal instances, inventory instances)
- Vendor compliance onboarding orchestration
- Session management with 2FA (Google reCAPTCHA Enterprise)
- NetSuite webhook ingestion for accounting events
- Ticket management and bank information capture
- Category, taxonomy, and geo-details lookup orchestration
- Avalara tax integration via V2 proxy

### Out of scope

- Storefront / consumer-facing product display (handled by Goods Product Catalog and Deal Catalog)
- Inventory reservation and fulfillment execution (handled by Goods Inventory Service)
- Pricing engine computation (handled by Pricing Service)
- Tax calculation engine (handled by Avalara via Accounting Service)
- Vendor payment processing (handled by Accounting Service)

## Domain Context

- **Business domain**: Goods Platform / Vendor Integration
- **Platform**: Continuum
- **Upstream consumers**: Goods Vendor Portal UI, NetSuite (webhook)
- **Downstream dependencies**: Goods Stores Service, Goods Inventory Service, Goods Product Catalog, Goods Promotion Manager, Deal Catalog, DMAPI, Pricing Service, Taxonomy Service, Users Service, Vendor Compliance Service, Commerce Interface, Geo Details Service, Accounting Service, Amazon S3, Google reCAPTCHA Enterprise

## Stakeholders

| Role | Description |
|------|-------------|
| Goods Vendor Portal engineers | Primary developers and maintainers of the service |
| Goods Platform team | Domain owners for vendor integration workflows |
| Finance / Accounting team | Consumers of NetSuite webhook and bank info data |
| Vendor Compliance team | Owners of compliance onboarding process orchestrated through this service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.7.8 | `.ruby-version`, `Gemfile` |
| Framework | Rails | 5.2.8 | `Gemfile.lock` |
| Runtime | Puma | 6.3.1 | `Gemfile`, `config/puma.rb` |
| Build tool | Bundler | 2.3.26 | `Gemfile.lock` |
| Package manager | Bundler | 2.3.26 | `Gemfile.lock` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| rest-client | 2.1.0 | http-framework | HTTP client for synchronous downstream service calls |
| typhoeus | 1.4.0 | http-framework | Parallel/concurrent HTTP requests to downstream services |
| schema_driven_client | 0.5.0 | http-framework | Schema-validated HTTP client wrapper for internal APIs |
| oauthenticator | 1.4.1 | auth | OAuth request signing and verification |
| google-cloud-recaptcha_enterprise | 1.5.1 | auth | reCAPTCHA Enterprise verification for session 2FA |
| config | 3.1.1 | configuration | Multi-environment config file management |
| sonoma-logger | 3.0.0 | logging | Structured JSON logging for Continuum services |
| sonoma-metrics | 0.9.0 | metrics | StatsD-compatible metrics emission |
| elastic-apm | 4.7.3 | metrics | Elastic APM distributed tracing agent |
| puma | 6.3.1 | http-framework | Multi-threaded Ruby application server |
| rspec-rails | 5.1.2 | testing | Rails-integrated RSpec test framework |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
