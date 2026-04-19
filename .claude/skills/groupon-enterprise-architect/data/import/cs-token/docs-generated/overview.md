---
service: "cs-token"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Customer Service / Commerce"
platform: "Continuum"
team: "GSO Engineering"
status: active
tech_stack:
  language: "Ruby"
  language_version: "2.6.3"
  framework: "Ruby on Rails"
  framework_version: ""
  runtime: "Unicorn"
  runtime_version: ""
  build_tool: "Bundler"
  package_manager: "Bundler / RubyGems"
---

# CS Token Service Overview

## Purpose

CS Token Service creates and verifies short-lived, method-scoped authorization tokens for Customer Service (CS) agents. It acts as an intermediary between Cyclops (the CS agent tooling frontend) and Lazlo (the order management API), allowing agents to perform scoped customer actions (view vouchers, create orders, issue refunds, etc.) without requiring full admin privileges. Tokens are generated with a random secret, optionally AES-256-GCM encrypted, and cached in Redis with configurable per-method TTLs.

## Scope

### In scope
- Generating scoped authorization tokens for CS agent actions on behalf of customers
- Verifying tokens on incoming requests (validating method, consumer ID, and expiration)
- Caching token payloads in Redis with per-method TTL
- Optional AES-256-GCM encryption of token keys before Redis storage
- API key authentication for token creation requests
- Client ID validation for token verification requests
- Test token creation endpoint (enabled only in non-production environments)

### Out of scope
- OAuth or identity provider integration (tokens are internally issued, not OAuth flows)
- Customer authentication or session management
- Storing any persistent data beyond token cache TTL
- Business logic execution (order creation, voucher retrieval) — delegated to Lazlo

## Domain Context

- **Business domain**: Customer Service / Commerce
- **Platform**: Continuum
- **Upstream consumers**: Cyclops (CS agent tooling), AppOps
- **Downstream dependencies**: Redis (token cache via `csTokenRedis`)

## Stakeholders

| Role | Description |
|------|-------------|
| GSO Engineering | Service owner and primary developer team |
| CS Agent | End user whose actions require scoped tokens |
| Cyclops | Primary caller — requests token creation and verification |
| AppOps | Secondary caller — requests token creation |
| PagerDuty on-call | Incident response via `customer-support-international@groupon.pagerduty.com` |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.6.3 | `.ruby-version`, `Dockerfile` |
| Framework | Ruby on Rails | (Gemfile `gem 'rails'`) | `Gemfile` |
| Runtime | Unicorn | (Gemfile `gem 'unicorn'`) | `Gemfile`, `Dockerfile` CMD |
| Build tool | Bundler | — | `Gemfile.lock`, `Dockerfile` |
| Package manager | RubyGems / Bundler | — | `Gemfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `rails` | (latest compatible) | http-framework | Web framework and routing |
| `unicorn` | (latest compatible) | http-framework | Multi-process Rack HTTP server |
| `redis` | (latest compatible) | db-client | Redis client for token cache |
| `resque` | (latest compatible) | scheduling | Redis connection management (tokenizer_redis namespace) |
| `redis-lock` | (latest compatible) | db-client | Distributed locking via Redis |
| `config` | (latest compatible) | configuration | YAML-based settings management per environment |
| `sonoma-logger` | (latest compatible) | logging | Groupon structured logger (STENO_LOGGER) |
| `sonoma-request-id` | (latest compatible) | logging | Request ID propagation for distributed tracing |
| `openssl` | stdlib | auth | AES-256-GCM token encryption |
| `base64` | stdlib | serialization | URL-safe Base64 encoding of encrypted tokens |
| `rspec-rails` | (latest compatible) | testing | RSpec test framework for Rails |
| `fakeredis` | (latest compatible) | testing | In-memory Redis stub for tests |
| `rubocop` | (latest compatible) | testing | Ruby static code analysis |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
