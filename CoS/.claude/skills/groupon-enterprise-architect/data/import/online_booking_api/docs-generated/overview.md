---
service: "online_booking_api"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Online Bookings / Local Commerce"
platform: "Continuum"
team: "Booking Tool"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.2.3"
  framework: "Rails"
  framework_version: "~> 5.0"
  runtime: "Puma"
  runtime_version: "3.12.6"
  build_tool: "Bundler"
  package_manager: "Bundler / RubyGems"
---

# Online Booking API Overview

## Purpose

The Online Booking API is a Ruby on Rails REST service that serves as the public gateway for Groupon's Local Booking System. It exposes versioned HTTP endpoints used by Zendesk CS tooling, merchant-facing UIs, and consumer-facing booking flows to create and manage reservations, query availability, and configure merchant booking settings. The service acts as an orchestration layer — it does not own data but coordinates calls across multiple internal booking engine services, enriches responses, and presents a stable API contract to its consumers.

## Scope

### In scope

- Exposing REST endpoints for reservation lifecycle management (create, read, update)
- Exposing REST endpoints for reservation request management (list, confirm, decline)
- Querying and returning availability segments for a given option and time range
- Orchestrating parallel calls to downstream services and merging enriched responses
- Serving booking settings (engine type, duration, flags, additional attributes) per option
- Managing place-level notification and appointment settings
- Logging contact attempts made by CS agents via Zendesk
- Managing availability override windows (create, list, delete)
- Exposing option-level booking flags (active, G3 status)

### Out of scope

- Owning or persisting reservation or appointment data (delegated to `continuumAppointmentsEngine`)
- Computing availability slots (delegated to `continuumAvailabilityEngine`)
- Sending booking notifications (delegated to `continuumOnlineBookingNotifications`)
- Managing deal and option catalog data (delegated to `continuumDealCatalogService`)
- User identity management (delegated to `continuumUsersService`)
- Voucher inventory management (delegated to `continuumVoucherInventoryService`)
- Calendar and schedule management (delegated to `continuumCalendarService`)

## Domain Context

- **Business domain**: Online Bookings / Local Commerce
- **Platform**: Continuum
- **Upstream consumers**: Zendesk CS application, merchant-facing booking tool UIs, consumer booking flows (identified by `client_id` + HMAC authentication)
- **Downstream dependencies**: `continuumAppointmentsEngine`, `continuumAvailabilityEngine`, `continuumCalendarService`, `continuumDealCatalogService`, `continuumM3PlacesService`, `continuumOnlineBookingNotifications`, `continuumUsersService`, `continuumVoucherInventoryService`

## Stakeholders

| Role | Description |
|------|-------------|
| Team Owner | Booking Tool team — `booking-tool-engineers@groupon.com` |
| SRE Alert Contact | `booking-engine-alerts@groupon.com` |
| On-call Escalation | PagerDuty service `PO6UE07` |
| Slack Channel | `CF9U0DPC3` |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.2.3 | `.ruby-version` |
| Framework | Rails | ~> 5.0 | `Gemfile` |
| Runtime | Puma | 3.12.6 | `Gemfile` |
| Build tool | Bundler | 1.17.3 | `.ci/Dockerfile` |
| Package manager | RubyGems / Bundler | | `Gemfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `rails` | ~> 5.0 | http-framework | Rails API application framework |
| `puma` | 3.12.6 | http-framework | Threaded web server (10 threads per `RAILS_MAX_THREADS`) |
| `api_clients` | ~> 2.0.1 | http-client | Service-discovery-aware HTTP client for all downstream calls |
| `json-schema` | latest | validation | JSON schema validation for request parameters |
| `link_header` | latest | serialization | Parses and rewrites `Link` pagination headers from upstream services |
| `sonoma-metrics` | latest | metrics | Rack middleware for emitting application metrics (Wavefront) |
| `skeletor_rails_gem` | 2.0.0 | http-framework | Groupon-internal Rails base gem providing API interface conventions |
| `nokogiri` | 1.8.2 | serialization | XML/HTML processing (pinned for compatibility with roller hosts) |
| `i18n` | <= 1.5.1 | http-framework | Internationalization (version pinned for Ruby 2.2 compatibility) |
| `capistrano` | ~> 3.4 | scheduling | Legacy deployment tooling (development only) |
| `rspec-rails` | ~> 3.0 | testing | Test framework |
| `webmock` | latest | testing | HTTP request stubbing for tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `Gemfile.lock` for a full list.
