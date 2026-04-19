---
service: "online_booking_3rd_party"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Booking / Local Services Commerce"
platform: "Continuum"
team: "Booking Engine"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.2.3"
  framework: "Rails"
  framework_version: "5.0.7"
  runtime: "Puma"
  runtime_version: "3.12.6"
  build_tool: "Bundler"
  package_manager: "Bundler / RubyGems"
---

# Online Booking 3rd Party Overview

## Purpose

The `online_booking_3rd_party` service is an adapter layer between Groupon's Booking Engine and external third-party scheduling systems such as Xola and Genbook. It manages the full lifecycle of merchant-to-provider mappings, synchronizes reservations and availability bidirectionally, and exposes REST endpoints consumed by other Booking Engine services. The service also processes asynchronous events from the Appointment Engine and Booking Tool to keep provider state consistent.

## Scope

### In scope

- Merchant place and provider authorization management (create, update, delete mappings)
- Service-level mapping between Groupon deals/options and provider service offerings
- Bidirectional availability synchronization (polling providers and ingesting push webhooks)
- Reservation creation and lifecycle management relayed to/from third-party providers
- Consuming events from Appointment Engine and Booking Tool topics
- Publishing domain events to `jms.topic.BookingEngine.3rdParty.Events`
- Scheduled polling orchestration for pollable merchant-place mappings
- Smoke-test endpoints for integration health verification

### Out of scope

- Consumer-facing booking UI (handled by Booking Tool / MBNXT)
- Payment processing (handled by Orders Service and Voucher Inventory)
- Native Groupon calendar management (handled by Calendar Service)
- Direct merchant management (handled by M3 Merchant)

## Domain Context

- **Business domain**: Booking / Local Services Commerce
- **Platform**: Continuum
- **Upstream consumers**: Booking Tool, Appointment Engine, Availability Engine, merchant-facing operator tooling
- **Downstream dependencies**: Appointment Engine, Availability Engine, Users Service, Deal Catalog, Deal Management API, Calendar Service, EMEA BTOS (3rd-party provider APIs), Voucher Inventory API, Orders Service, Message Bus

## Stakeholders

| Role | Description |
|------|-------------|
| Booking Engine Team | Owns and operates this service |
| Merchant Operations | Uses mapping and authorization workflows to connect providers |
| 3rd-Party Provider Partners | External scheduling systems (Xola, Genbook, etc.) integrated via their APIs |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.2.3 | Service inventory |
| Framework | Rails | 5.0.7 | Service inventory / Gemfile |
| Runtime | Puma | 3.12.6 | Service inventory |
| Build tool | Bundler | — | RubyGems convention |
| Package manager | RubyGems / Bundler | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| rails | 5.0.7 | http-framework | Web framework and ORM base |
| mysql2 | — | db-client | MySQL adapter for ActiveRecord |
| redis | — | db-client | Redis connection for Resque and caching |
| resque | — | scheduling | Background job processing framework |
| resque-scheduler | — | scheduling | Cron-style job scheduling on top of Resque |
| active_scheduler | 0.5.0 | scheduling | ActiveJob-compatible scheduler integration |
| messagebus | 0.5.2 | message-client | STOMP/JMS messaging for event publish/consume |
| dalli | 2.7.6 | db-client | Memcached client for application-level caching |
| groupon_platform | — | http-framework | Shared Groupon service client and auth helpers |
| money | — | validation | Currency and monetary value handling |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
