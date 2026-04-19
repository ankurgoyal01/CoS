---
service: "clo-service"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Card-Linked Offers"
platform: "Continuum"
team: "CLO Team (sox-inscope)"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.6.8"
  framework: "Rails"
  framework_version: "5.2.4.2"
  runtime: "JRuby"
  runtime_version: "9.3.15.0"
  build_tool: "Bundler"
  package_manager: "Bundler / RubyGems"
---

# CLO Service Overview

## Purpose

CLO Service (Card-Linked Offers) is the Continuum platform service responsible for managing card-linked offer programs end-to-end. It handles card enrollment with Visa, Mastercard, and Amex networks, processes claims and statement credits when consumers make qualifying purchases, and distributes offer inventory to card network partners. The service is SOX in-scope due to its role in financial transaction processing and rewards redemption.

## Scope

### In scope

- Card enrollment — linking consumer payment cards to active CLO offers via Visa, Mastercard, and Amex APIs
- Claim ingestion — receiving purchase transaction callbacks from card networks and matching them to enrolled offers
- Statement credit processing — triggering and tracking loyalty statement credits for qualifying claims
- Rewards Network integration — coordinating offer activation and redemption with Rewards Network
- Offer lifecycle management — ingesting, distributing, and syncing CLO deal inventory
- User account lifecycle handling — responding to account creation, suspension, and GDPR erasure events
- Merchant ingestion — processing merchant offer data via `/api/v1/offers` and `/api/v1/merchant/ingestion`
- Admin interface — ActiveAdmin-based management UI for internal operators
- Salesforce integration — reading onboarding and CRM context for merchants
- Scheduled reporting — periodic health reports and background pipeline jobs

### Out of scope

- Payment processing and financial settlement — handled by Orders Service and billing infrastructure
- Consumer-facing deal discovery — handled by Deal Catalog Service and MBNXT frontend
- Merchant onboarding UI — handled by Merchant Advisor and related services
- Card network contract negotiation — handled outside engineering systems
- General loyalty programs not tied to card transactions

## Domain Context

- **Business domain**: Card-Linked Offers
- **Platform**: Continuum
- **Upstream consumers**: Card networks (Visa, Mastercard, Amex) via webhook callbacks; internal services via Message Bus; operators via Admin UI
- **Downstream dependencies**: Visa, Mastercard, Amex (card network APIs), Rewards Network, Salesforce, Orders Service (`continuumOrdersService`), Users Service (`continuumUsersService`), Deal Catalog Service (`continuumDealCatalogService`), M3 Merchant Service (`continuumM3MerchantService`), Merchant Advisor (`merchantAdvisorService`), CLO Inventory Service (`continuumCloInventoryService`), Third-Party Inventory Service (`continuumThirdPartyInventoryService`), Message Bus (`messageBus`)

## Stakeholders

| Role | Description |
|------|-------------|
| CLO Team | Service owners; responsible for development, operations, and SOX compliance |
| Finance / Compliance | SOX audit stakeholders due to statement credit and transaction flows |
| Merchant Partners | Merchants whose offers are enrolled and tracked through the service |
| Card Network Partners | Visa, Mastercard, Amex — provide transaction callbacks and enrollment APIs |
| Internal Operators | Use the ActiveAdmin UI for offer and enrollment management |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.6.8 | JRuby runtime target |
| Framework | Rails | 5.2.4.2 | Gemfile |
| Runtime | JRuby | 9.3.15.0 | .ruby-version / Gemfile |
| Web server | Puma | — | Gemfile |
| Build tool | Bundler | — | Gemfile.lock |
| Package manager | RubyGems / Bundler | — | Gemfile |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| sidekiq | latest compat | scheduling | Background job processing for async CLO workflows |
| sidekiq-scheduler | — | scheduling | Recurring cron-style job scheduling |
| Faraday | — | http-framework | Outbound HTTP client for partner and internal service calls |
| redis-rails | — | db-client | Redis session store and cache integration |
| messagebus | 0.5.3 | message-client | Publish and consume Message Bus topics |
| ar-octopus | ~0.10 | orm | Database sharding support for ActiveRecord |
| ActiveAdmin | 1.4.2 | ui-framework | Admin interface for internal operators |
| AASM | ~5.0.0 | state-management | Finite state machine for claim and enrollment lifecycle |
| Pundit | 1.1.0 | auth | Authorization policies for admin and API access |
| Restforce | ~3.1.0 | http-framework | Salesforce REST API client |
| Savon | — | http-framework | SOAP client for card network integrations requiring SOAP/XML |
