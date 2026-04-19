---
service: "appointment_engine"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Booking / Services"
platform: "continuum"
team: "Booking Tool Engineers (booking-tool-engineers@groupon.com)"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.2.3"
  framework: "Rails"
  framework_version: "5.0.7"
  runtime: "Puma"
  runtime_version: "3.12.6"
  build_tool: "Capistrano 3.11.0"
  package_manager: "Bundler"
---

# Appointment Engine Overview

## Purpose

The appointment engine is a Rails API service that manages the full lifecycle of appointments for Groupon's Appointments Voucher Booking product. It handles reservation requests, availability coordination, appointment confirmation/decline/reschedule, consumer notifications, and GDPR data deletion. The service acts as the central state machine for appointment records, coordinating with the Availability Engine, Deal Catalog, Orders Service, and merchant-facing notification systems.

## Scope

### In scope

- Creating and managing reservation requests (V2 API) and reservations (V3 API)
- Appointment state machine transitions: confirm, decline, reschedule, attend, miss
- Exposing appointment parameters (options, flags) to consumers and merchants
- Processing availability events from the Availability Engine
- Processing order status change events from the Orders / Inventory services
- Sending appointment notifications via the Online Booking Notifications service
- Tracking consumer contact attempts and ticket states
- Supporting GDPR account erasure requests
- Providing voucher status information
- Background job processing via Resque workers (`continuumAppointmentEngineUtility`)
- Scheduled periodic data cleanup jobs via resque-scheduler

### Out of scope

- Availability slot management and calendar scheduling (handled by Availability Engine and Calendar Service)
- Payment processing and order creation (handled by Orders Service)
- Merchant onboarding and profile management (handled by M3 / Places services)
- Deal catalog management (handled by Deal Catalog service)
- Consumer authentication (handled by Users Service)

## Domain Context

- **Business domain**: Booking / Services
- **Platform**: continuum
- **Upstream consumers**: Groupon consumer-facing deal page (appointment booking UI), merchant-facing booking management tools, EMEA BTOS (Booking Tool for Online Services)
- **Downstream dependencies**: Availability Engine, Deal Catalog, Orders Service, Voucher Inventory Service, M3 Merchant/Places, Users Service, Calendar Service, Online Booking Notifications, API Lazlo, Message Bus

## Stakeholders

| Role | Description |
|------|-------------|
| Groupon Consumer | Books appointments via Groupon deal page; receives booking confirmations |
| Groupon Merchant | Confirms, declines, or reschedules consumer appointments |
| Booking / Services Team | Service owners responsible for the appointment booking product |
| GDPR / Privacy Team | Requires data deletion capability for GDPR erasure requests |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.2.3 | .ruby-version / Gemfile |
| Framework | Rails | 5.0.7 | Gemfile |
| Runtime | Puma | 3.12.6 | Gemfile |
| Build tool | Capistrano | 3.11.0 | Gemfile / Capfile |
| Package manager | Bundler | — | Gemfile.lock |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Rails | 5.0.7 | http-framework | MVC web framework; API mode for REST endpoints |
| mysql2 | — | db-client | MySQL database adapter for ActiveRecord |
| resque | — | scheduling | Redis-backed background job processing |
| resque-scheduler | — | scheduling | Cron-style scheduled job management on top of Resque |
| redis | — | db-client | Redis client for Resque job queue |
| dalli | 2.7.8 | db-client | Memcached client for API response caching |
| messagebus | 0.5.2 | message-client | Client for Groupon Message Bus (JMS topic pub/sub) |
| state_machine | 1.2.0 | validation | Appointment lifecycle state machine transitions |
| active_scheduler | 0.5.0 | scheduling | ActiveRecord-backed scheduler integration |
| api_clients | 2.0.1 | http-client | Internal Groupon API client library |
| sonoma-metrics | — | metrics | Metrics emission for Groupon monitoring infrastructure |
| kaminari | — | validation | Pagination for API list responses |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
