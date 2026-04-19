---
service: "glive-inventory-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Live Events & Ticketing"
platform: "Continuum"
team: "GrouponLive Engineering"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.x"
  framework: "Rails"
  framework_version: "4.2"
  runtime: "MRI Ruby"
  runtime_version: "2.x"
  build_tool: "Bundler / Rake"
  package_manager: "Bundler"
---

# GLive Inventory Service Overview

## Purpose

GLive Inventory Service is the central API and processing backend for GrouponLive's third-party ticket inventory. It manages the full lifecycle of live-event ticket products -- from inventory creation and availability queries, through reservation and purchase orchestration with external ticketing partners (Ticketmaster, AXS, Telecharge, ProVenue), to merchant payment reporting. The service exists to bridge Groupon's commerce platform with third-party ticketing providers, enabling Groupon to sell live-event tickets sourced from multiple external inventory systems through a unified API.

## Scope

### In scope

- Third-party ticket inventory creation, update, and deletion
- Event and product availability queries with HTTP caching (Varnish)
- Ticket reservation lifecycle (create, hold, release, expire)
- Purchase orchestration across Ticketmaster, AXS, Telecharge, and ProVenue APIs
- Background job processing for long-running third-party integrations (Resque/ActiveJob workers)
- Merchant payment and accounting report generation
- Cache management and invalidation (Redis + Varnish)
- GDPR data handling and compliance event processing
- Admin UI API for operational workflows
- Inventory and configuration event publishing/consuming via MessageBus

### Out of scope

- Deal creation and lifecycle management (handled by Deal Management API)
- Order processing and payment capture (handled by Orders Service and GTX Service)
- Customer-facing web UI rendering (handled by Groupon Website / MBNXT)
- Email delivery (delegated to Mailman Service)
- Geodetail and division data (sourced from Bhuvan Service)
- General inventory management for non-live-event products

## Domain Context

- **Business domain**: Live Events & Ticketing (GrouponLive)
- **Platform**: Continuum Commerce Platform
- **Upstream consumers**: Groupon Website (`continuumGrouponWebsite`), GLive Inventory Admin (`continuumGliveInventoryAdmin`), Varnish HTTP Cache (`continuumGliveInventoryVarnish`)
- **Downstream dependencies**: Ticketmaster API (`continuumTicketmasterApi`), AXS API (`continuumAxsApi`), Telecharge Partner (`continuumTelechargePartner`), ProVenue Partner (`continuumProvenuePartner`), GTX Service (`continuumGtxService`), Accounting Service (`continuumAccountingService`), Mailman Service (`continuumMailmanService`), MessageBus (`messageBus`)

## Stakeholders

| Role | Description |
|------|-------------|
| GrouponLive Engineering | Owns and maintains the service, develops new integrations |
| GrouponLive Operations | Uses Admin UI for day-to-day inventory and event management |
| Merchant Operations | Relies on payment reports and accounting data |
| Platform Engineering | Maintains shared infrastructure (MessageBus, Redis, MySQL) |
| Third-Party Partners | Ticketmaster, AXS, Telecharge, ProVenue provide ticket inventory APIs |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.x | Gemfile |
| Framework | Ruby on Rails | 4.2 | Gemfile / architecture DSL |
| Runtime | MRI Ruby | 2.x | Gemfile |
| Build tool | Bundler / Rake | — | Gemfile / Rakefile |
| Package manager | Bundler | — | Gemfile.lock |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Rails | 4.2 | http-framework | Web application framework for HTTP API controllers |
| ActiveRecord | 4.2 | orm | ORM for MySQL database access |
| Resque | — | scheduling | Background job queue backed by Redis |
| ActiveJob | 4.2 | scheduling | Rails job abstraction layer over Resque |
| Faraday | — | http-framework | HTTP client for external service integrations |
| service_discovery_client | — | http-framework | Service discovery for internal Groupon services |
| Clientable | — | http-framework | HTTP client DSL for building service clients |
| Steno Logger | — | logging | Structured logging |
| Sonoma | — | metrics | Metrics and logging integration |
| Elastic APM | — | metrics | Application performance monitoring and tracing |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
