---
service: "consumer-data"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Consumer Profile / User Accounts"
platform: "continuum"
team: "Users Team (consumer-data-service@groupon.com)"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.6.5"
  framework: "Sinatra"
  framework_version: "2.1.0"
  runtime: "Puma"
  runtime_version: "5.3.2"
  build_tool: "Bundler"
  package_manager: "Bundler"
---

# Consumer Data Service 2.0 Overview

## Purpose

Consumer Data Service 2.0 is the authoritative source of consumer profile data within the Continuum platform. It exposes HTTP APIs for reading and writing consumer records, location data, and user preferences, and propagates changes asynchronously via MessageBus to downstream services. It also processes inbound events for account lifecycle operations such as GDPR erasure and new account creation.

## Scope

### In scope

- CRUD operations on consumer profiles (`consumers` table)
- CRUD operations on consumer locations (`locations` table)
- CRUD operations on consumer preferences (`preferences` table)
- Publishing consumer change events to MessageBus topics
- Handling GDPR account erasure requests end-to-end
- Handling new account creation events from the Users Service
- Health and heartbeat endpoints for infrastructure monitoring

### Out of scope

- User authentication and identity management (handled by Users Service)
- Payment method storage (handled by payment services)
- Order history and transaction records (handled by order services)
- Frontend rendering (handled by MBNXT / pwa)

## Domain Context

- **Business domain**: Consumer Profile / User Accounts
- **Platform**: continuum
- **Upstream consumers**: Checkout services, order management, pwa (legacy consumer data reads)
- **Downstream dependencies**: bhoomi (GeoDetails lookup), bhuvan (external data), MessageBus (event publishing), Users Service (account creation events), MySQL (primary data store)

## Stakeholders

| Role | Description |
|------|-------------|
| Users Team | Service owner; responsible for maintenance and on-call (consumer-data-service@groupon.com) |
| Checkout Engineers | Primary API consumers integrating consumer data at checkout |
| Data Privacy / Legal | Rely on GDPR erasure flow for compliance |
| Platform Engineering | Maintain MessageBus and service-discovery infrastructure |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.6.5 | Inventory / Gemfile |
| Framework | Sinatra | 2.1.0 | Inventory / Gemfile |
| Runtime | Puma | 5.3.2 | Inventory / Gemfile |
| Build tool | Bundler | — | Gemfile.lock |
| Package manager | Bundler | — | Gemfile |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| sinatra | 2.1.0 | http-framework | HTTP routing and request handling |
| activerecord | 6.1.3.2 | orm | Database access and migrations |
| mysql2 | 0.5.3 | db-client | MySQL adapter for ActiveRecord |
| messagebus | 0.3.7 | message-client | Publish and consume MessageBus events |
| sonoma-logger | 3.0.0 | logging | Structured JSON logging |
| sonoma-metrics | 0.8.0 | metrics | Application metrics emission |
| typhoeus | 1.4.0 | http-framework | Outbound HTTP client (bhoomi, bhuvan calls) |
| service_discovery_client | 2.2.3 | http-framework | Resolves internal service endpoints |
| oj | 3.11.5 | serialization | Fast JSON serialization |
| rspec | 3.10.0 | testing | Unit and integration test framework |
| capistrano | 3.16.0 | scheduling | Deployment automation |
| better_backfills | 0.3.0 | scheduling | Safe database backfill tooling |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
