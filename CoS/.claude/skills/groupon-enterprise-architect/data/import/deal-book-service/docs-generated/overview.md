---
service: "deal-book-service"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Deal Management / Sales"
platform: "continuum"
team: "Deal Management Team"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.2.10"
  framework: "Rails"
  framework_version: "3.2.22.5"
  runtime: "Ruby"
  runtime_version: "2.2.10"
  build_tool: "Bundler"
  package_manager: "Bundler"
---

# Deal Book Service Overview

## Purpose

Deal Book Service is the authoritative source of truth for structured fine print content used in Groupon deal creation. It manages fine print clauses — the legal and operational terms attached to deals — sourcing them from Google Sheets and exposing a versioned API for consumers such as Deal Wizard. The service compiles clause sets into persisted fine prints for individual deals and keeps content synchronized with taxonomy updates through event-driven processing.

## Scope

### In scope

- Serving fine print clause recommendations by geography and taxonomy
- Compiling fine print clause sets into a single structured fine print for a deal
- Persisting and managing fine print sets (create, read, update, delete) per deal
- Content versioning for fine print clauses (`/content_version`)
- Synchronizing fine print clause content from Google Sheets (scheduled refresh)
- Processing taxonomy change events to keep clause-category mappings current
- Salesforce external UUID mapping for fine print records
- Multi-language support for fine print content (via `globalize`)

### Out of scope

- Deal creation, pricing, or booking (handled by Deal Wizard and other Deal Management services)
- Consumer-facing display of fine print (rendered by frontend services)
- Merchant or place management (M3 system)
- Order processing or payment

## Domain Context

- **Business domain**: Deal Management / Sales
- **Platform**: Continuum
- **Upstream consumers**: Deal Wizard (`continuumDealWizard`); other deal creation tools that call the API
- **Downstream dependencies**: Google Sheets API (content source), Taxonomy Service, Model API, Salesforce (external UUID mapping)

## Stakeholders

| Role | Description |
|------|-------------|
| Sales / Deal Creation Team | Uses fine print data surfaced through Deal Wizard to build deals |
| Deal Management Team | Owns and maintains the service |
| Content Authors | Manage fine print clause content in Google Sheets |
| Deal Wizard | Primary API consumer for fine print compilation and persistence |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.2.10 | Gemfile / `.ruby-version` |
| Framework | Rails | 3.2.22.5 | Gemfile |
| Runtime | Ruby | 2.2.10 | Runtime environment |
| Build tool | Bundler | — | Gemfile |
| Package manager | Bundler | — | Gemfile |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| rails | 3.2.22.5 | http-framework | Core web framework, routing, API structure |
| mysql2 | 0.3.14 | db-client | MySQL database adapter for fine print data store |
| redis | 3.3.1 | db-client | Redis client for response caching |
| google_drive | 3.0.0 | http-client | Google Sheets API integration for fine print content sourcing |
| messagebus | 0.2.15 | message-client | Message bus consumer for taxonomy update events |
| faraday | 0.17.3 | http-client | HTTP client for internal service calls (Taxonomy, Model API) |
| taxonomy_service_client | — | http-client | Client gem for Taxonomy Service integration |
| model_api_client | 0.1.1 | http-client | Client gem for Model API integration |
| globalize | 3.1.0 | serialization | ActiveRecord translation/internationalization for multi-language fine print |
| whenever | 0.9.4 | scheduling | Cron-based scheduling for rake task jobs (Google Sheets refresh) |
| sonoma-metrics | 0.8.0 | metrics | Sonoma platform metrics reporting |
| sonoma-logger | 3.0.0 | logging | Structured logging for the Continuum platform |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
