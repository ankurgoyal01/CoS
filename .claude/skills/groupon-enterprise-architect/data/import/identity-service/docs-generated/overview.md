---
service: "identity-service"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "User Identity / GDPR Compliance"
platform: "Continuum"
team: "Identity / Account Management"
status: active
tech_stack:
  language: "Ruby"
  language_version: "3.0.2"
  framework: "Sinatra"
  framework_version: "3.x"
  runtime: "Puma"
  runtime_version: ""
  build_tool: "Bundler"
  package_manager: "Bundler / Gemfile"
---

# Identity Service Overview

## Purpose

identity-service is the authoritative identity and account management service for the Groupon ecosystem. It provides a REST API for creating, reading, updating, and erasing user identity records, and fulfills GDPR erasure obligations by processing account deletion requests asynchronously. The service bridges identity data across Continuum (PostgreSQL) and PWA (MySQL) platforms while publishing lifecycle events to downstream consumers via the Groupon Message Bus.

## Scope

### In scope

- Creating and managing user identity records with UUID-based identification
- Serving identity lookups and updates via a versioned REST API with Bearer JWT authentication
- Publishing identity lifecycle events (`created`, `erased`, `updated`) to the Message Bus
- Processing GDPR erasure requests asynchronously via a dedicated Mbus consumer worker
- Publishing `gdpr.account.v1.erased.complete` events upon successful erasure
- Consuming dog-food audit events for internal audit trail maintenance
- Maintaining an API key registry for service-to-service authentication
- Caching identity data in Redis via Resque-backed background jobs

### Out of scope

- Authentication (login, session management, OAuth flows) — handled by upstream auth services
- Authorization policy enforcement — responsibility of calling services
- User profile data beyond identity attributes — handled by dedicated profile services
- Password management
- Frontend or UI rendering

## Domain Context

- **Business domain**: User Identity / GDPR Compliance
- **Platform**: Continuum
- **Upstream consumers**: Groupon web and mobile applications, partner services, the GDPR Platform, RaaS (Rewards-as-a-Service)
- **Downstream dependencies**: PostgreSQL (primary identity store), MySQL (PWA data), Redis (cache and job queue), Message Bus (Thrift g-bus), GDPR Platform, RaaS

## Stakeholders

| Role | Description |
|------|-------------|
| Identity / Account Management Team | Owns and maintains this service |
| GDPR / Privacy Engineering | Drives erasure compliance requirements |
| Platform Engineering | Provides infrastructure (Mbus, Redis, PostgreSQL) |
| Consuming Application Teams | Integrate against the identity REST API and events |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 3.0.2 | Gemfile / .ruby-version |
| Framework | Sinatra | 3.x | Gemfile |
| Runtime | Puma | — | Gemfile |
| Build tool | Bundler | — | Gemfile.lock |
| Package manager | Bundler / Gemfile | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| sinatra | 3.x | http-framework | Lightweight HTTP API framework |
| sinatra-activerecord | — | orm | ActiveRecord integration for Sinatra |
| activerecord | 7.0.4 | orm | ORM for PostgreSQL and MySQL data access |
| mysql2 | — | db-client | MySQL adapter for ActiveRecord (PWA data) |
| pg | — | db-client | PostgreSQL adapter for ActiveRecord (primary identity store) |
| messagebus | 0.3.6 | message-client | Groupon Message Bus publishing client |
| g-bus | 0.0.1 | message-client | Groupon bus library for Thrift-based event consumption |
| redis | 4.7.1 | db-client | Redis client for caching and Resque queue |
| resque | — | scheduling | Background job processing backed by Redis |
| jwt | 2.5.0 | auth | JWT decoding and verification for Bearer token auth |
| rack-attack | — | validation | Request throttling and blocking at the Rack layer |
| rtier-logger | — | logging | Structured logging for Continuum services |
| sonoma-logger | — | metrics | Sonoma-compatible metrics emission |

Categories: `http-framework`, `orm`, `db-client`, `message-client`, `auth`, `logging`, `metrics`, `serialization`, `testing`, `ui-framework`, `state-management`, `validation`, `scheduling`

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
