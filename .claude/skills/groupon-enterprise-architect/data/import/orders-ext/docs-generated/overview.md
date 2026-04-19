---
service: "orders-ext"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Orders / Fraud & Payments"
platform: "Continuum"
team: "Orders Team"
status: active
tech_stack:
  language: "Ruby"
  language_version: "3.0.4"
  framework: "Rails"
  framework_version: "7.0.3"
  runtime: "Puma"
  runtime_version: "~> latest"
  build_tool: "Rake"
  package_manager: "Bundler"
---

# Orders Ext Overview

## Purpose

Orders Ext is a Rails API service that acts as an inbound webhook gateway for fraud review and payment event partners. It receives fraud resolution callbacks from Accertify and Signifyd, payment lifecycle notifications from KillBill (Adyen gateway), and billing agreement cancellation events from PayPal, then routes each event to the appropriate internal Groupon system for order state transitions or billing record updates.

## Scope

### In scope

- Receiving and authenticating XML fraud resolution callbacks from Accertify
- Receiving and authenticating JSON fraud decision webhooks from Signifyd and forwarding to Fraud Arbiter Service
- Proxying KillBill/Adyen payment notification events by region (US, EMEA)
- Receiving PayPal billing agreement cancellation webhooks, verifying their authenticity with PayPal, and publishing a `PaypalBillingAgreementCancelled` message to the internal message bus
- Enqueuing async order resolution jobs (ACCEPT/REJECT) via Resque backed by Redis

### Out of scope

- Processing or executing order resolution logic (handled by orders-worker consuming the Resque queue)
- Storing order or payment data persistently (stateless beyond the Redis job queue)
- Direct payment initiation or refund operations
- User-facing UI or customer-initiated API calls

## Domain Context

- **Business domain**: Orders / Fraud & Payments
- **Platform**: Continuum
- **Upstream consumers**: Accertify (fraud partner), Signifyd (fraud partner), KillBill/Adyen (payment processor), PayPal (payment partner)
- **Downstream dependencies**: Fraud Arbiter Service, Users Service, KillBill (proxied), PayPal API, Resque/Redis queue, internal MessageBus

## Stakeholders

| Role | Description |
|------|-------------|
| Orders Team | Service owner; receives alerts in `#orders-ext-bots` |
| Fraud & Risk Team | Consumers of Accertify and Signifyd decision pipelines |
| Payments Team | Depends on KillBill and PayPal webhook routing |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 3.0.4 | `.ci/Dockerfile` |
| Framework | Rails | ~> 7.0.3 | `Gemfile` |
| Runtime | Puma | latest | `Gemfile`, `bin/puma` |
| Build tool | Rake | bundled with Rails | `Rakefile` |
| Package manager | Bundler | 1.17.3+ | `README.md`, `Gemfile.lock` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `rails` | ~> 7.0.3 | http-framework | Rails API framework; routing and controller layer |
| `puma` | latest | http-framework | Multi-threaded web server; 4 workers × up to 10 threads |
| `resque` | latest | scheduling | Background job enqueuing to Redis-backed queue |
| `messagebus` | latest | message-client | STOMP-based message bus client for publishing JMS topics |
| `schema_driven_client` | latest | http-client | Schema-driven HTTP client for calls to internal services (PayPal, KillBill, Fraud Arbiter, Users Service) |
| `faraday` | ~> 1.0 | http-client | HTTP adapter used by schema_driven_client |
| `typhoeus` | latest | http-client | libcurl-based HTTP client used for KillBill notification forwarding |
| `nokogiri` | latest | serialization | XML parsing for Accertify order resolution callbacks |
| `sonoma-logger` | latest | logging | Structured logging via STENO_LOGGER |
| `sonoma-metrics` | latest | metrics | Application metrics reporting |
| `sonoma-request-id` | latest | logging | Request correlation ID propagation |
| `hashie` | latest | serialization | Flexible hash-based data structures |
| `bootsnap` | latest | http-framework | Boot time optimization |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
