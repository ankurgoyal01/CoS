---
service: "deal_wizard"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Deal Creation / Sales Integration"
platform: "Continuum"
team: "sfint-dev@groupon.com (dbertelkamp)"
status: active
tech_stack:
  language: "Ruby"
  language_version: "1.9.3"
  framework: "Rails"
  framework_version: "3.2.22.5"
  runtime: "Unicorn"
  runtime_version: "6.1.0"
  build_tool: "Bundler"
  package_manager: "Bundler / RubyGems"
---

# Deal Wizard Overview

## Purpose

Deal Wizard is an internal sales tool that guides Groupon sales representatives through a structured, wizard-based deal creation process. It integrates with Salesforce as its system of record for Opportunities and Accounts, and surfaces relevant deal templates, pricing questions, locale configuration, and fine-print options to ensure deals are created with complete and valid data. The service reduces manual data entry errors by enforcing a sequential, validated workflow from opportunity identification through deal submission.

## Scope

### In scope

- Wizard-driven deal creation flow from Salesforce Opportunity to submitted deal
- Deal option configuration (pricing, discount, quantity, voucher values)
- Merchant fine-print selection and locale-specific configuration
- Deal approval workflow initiation and tracking
- Inventory allocation via Voucher Inventory Service
- Adoption rate and outstanding voucher reporting endpoints
- Admin dashboard for Salesforce error monitoring
- Salesforce OAuth authentication for sales users

### Out of scope

- Salesforce CRM management (owned by Salesforce)
- Consumer-facing deal display and purchase (owned by MBNXT / consumer web)
- Order processing and payment capture (owned by Continuum Order Management)
- Merchant portal self-service (owned by Self Services Service Engine)
- M3 merchant data management (owned by M3 Merchant Write API)

## Domain Context

- **Business domain**: Deal Creation / Sales Integration
- **Platform**: Continuum
- **Upstream consumers**: Sales representatives (internal browser-based users)
- **Downstream dependencies**: Salesforce (OAuth + APEX API), Deal Management API (`continuumDealManagementApi`), Voucher Inventory Service (`continuumVoucherInventoryService`), Deal Book Service (stub), Deal Guide Service (stub)

## Stakeholders

| Role | Description |
|------|-------------|
| Team Lead / Owner | dbertelkamp — primary code owner |
| Sales Integration Team | sfint-dev@groupon.com — engineering team responsible for Salesforce-integrated tooling |
| Sales Representatives | Internal Groupon sales users who create deals via the wizard UI |
| Deal Operations | Teams relying on deal data correctness and submission status |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 1.9.3 | Gemfile / .ruby-version |
| Framework | Rails | 3.2.22.5 | Gemfile (rails gem) |
| Runtime | Unicorn | 6.1.0 | Gemfile (unicorn gem) |
| Build tool | Bundler | — | Gemfile.lock |
| Package manager | RubyGems / Bundler | — | Gemfile |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| mysql2 | 0.3.21 | db-client | MySQL adapter for ActiveRecord — deal templates, questions, locales, fine prints |
| omniauth-salesforce | 1.0.5 | auth | OAuth 2.0 authentication against Salesforce for sales user sessions |
| databasedotcom | 1.3.2.gpn2 | http-framework | Salesforce REST/APEX API client (Groupon-patched fork) |
| salesforce-buffet | 0.0.5 | http-framework | Higher-level Salesforce API wrapper used by `salesforceClient` component |
| service_discovery_client | 0.1.13 | http-framework | Service discovery and HTTP client for internal Groupon services |
| redis | — | db-client | Redis client for session caching and feature flag reads |
| delayed_job | 4.0.0 | scheduling | Background job processing for async Salesforce operations |
| newrelic_rpm | 3.7.1 | metrics | New Relic APM agent for performance monitoring and error tracking |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
