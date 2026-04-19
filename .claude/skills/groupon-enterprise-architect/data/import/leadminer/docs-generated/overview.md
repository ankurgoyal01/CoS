---
service: "leadminer"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Merchant Data (M3 System)"
platform: "continuum"
team: "Merchant Data Team"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.2.3"
  framework: "Rails"
  framework_version: "3.2.22.3"
  runtime: "Ruby"
  runtime_version: "2.2.3"
  build_tool: "Bundler"
  package_manager: "Bundler 1.17.2"
---

# Leadminer (M3 Editor) Overview

## Purpose

Leadminer is a web-based editorial and inspection tool for managing M3 Places and Merchants data on the Continuum platform. It provides internal operators with search, view, edit, merge, and defrank capabilities over place and merchant records stored in the M3 system. The service acts as the primary human interface into M3 data — all persistent changes flow through downstream M3 APIs rather than a local database.

## Scope

### In scope

- Searching, browsing, and editing M3 Place records via `/p` routes
- Searching, browsing, and editing M3 Merchant records via `/m` routes
- Merging duplicate Place records (`/p/merge`)
- Defranking Place records (`/p/defrank`)
- Autocomplete for place search (`/p/autocomplete`)
- Viewing input history for places and merchants (`/i`)
- Managing internal users (`/u`)
- Surfacing business category and service lookups (`/api/business_categories`, `/api/services`)
- Geocode lookup for address resolution (`/api/geocode`)
- Phone number validation using a bundled JSON phone DB

### Out of scope

- Persistent storage of Place or Merchant data (owned by M3 backend services)
- Deal or order management (other Continuum services)
- Consumer-facing web pages or APIs
- Direct database access to M3 data stores

## Domain Context

- **Business domain**: Merchant Data (M3 System)
- **Platform**: Continuum
- **Upstream consumers**: Internal operators (human users via browser); Control Room (authentication provider)
- **Downstream dependencies**: Place Read Service, Place Write Service, M3 Merchant Service, Input History Service, BoomStick Service, Taxonomy Service, GeoDetails Service, Salesforce

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant Data Operators | Primary users who search, edit, and manage place/merchant records |
| Merchant Data Team | Owns and maintains the service |
| Control Room | Provides authentication for user sessions |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.2.3 | `.ruby-version` / Gemfile |
| Framework | Rails | 3.2.22.3 | Gemfile |
| Runtime | Ruby | 2.2.3 | `.ruby-version` |
| Build tool | Bundler | 1.17.2 | Gemfile.lock |
| Package manager | Bundler | 1.17.2 | Gemfile |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| rails | 3.2.22.3 | http-framework | Core web framework, routing, MVC |
| m3_client | 3.14.0 | http-client | Client gem for all M3 service API calls |
| haml | 4.0.5 | ui-framework | HTML template engine for views |
| jquery-rails | 3.1.0 | ui-framework | jQuery integration for browser-side interactivity |
| global_phone | 1.0.1 | validation | International phone number parsing and validation |
| will_paginate | latest | ui-framework | Pagination for search result lists |
| sonoma-metrics | 0.9.0 | metrics | Sonoma platform metrics reporting |
| sonoma-logger | 3.0.0 | logging | Structured logging for Sonoma/Continuum platform |
| rspec-rails | 3.0.0 | testing | RSpec test framework integration for Rails |
| capybara | 2.6.0 | testing | Integration/acceptance test helpers |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
