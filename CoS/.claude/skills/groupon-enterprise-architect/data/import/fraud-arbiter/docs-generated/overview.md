---
service: "fraud-arbiter"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Fraud Prevention / Risk Management"
platform: "continuum"
team: "Risk Platform"
status: active
tech_stack:
  language: "Ruby"
  language_version: ""
  framework: "Ruby on Rails"
  framework_version: ""
  runtime: "Ruby / Rails"
  runtime_version: ""
  build_tool: "Bundler"
  package_manager: "Bundler"
---

# Fraud Arbiter Overview

## Purpose

Fraud Arbiter is a Rails API and background job service that orchestrates order fraud reviews across third-party fraud providers (Signifyd and Riskified). It receives fraud decisions via webhooks, evaluates orders against fraud risk signals, and notifies downstream services of approve or reject outcomes. The service acts as the central arbiter between Groupon's commerce pipeline and external fraud intelligence providers.

## Scope

### In scope

- Receiving and validating inbound fraud-decision webhooks from Signifyd and Riskified
- Routing orders to the appropriate fraud provider for evaluation
- Persisting fraud decisions, events, and audit records to MySQL
- Publishing fraud decision events to downstream consumers via the message bus
- Processing asynchronous fraud tasks via Sidekiq background jobs (Redis queue)
- Sending fulfillment, return, and cancellation status updates back to fraud providers
- Exposing internal API endpoints for querying order fraud review status

### Out of scope

- Order creation and lifecycle management (handled by Orders Service)
- Payment processing and charge operations (handled by Kill Bill Payments)
- Voucher inventory and redemption (handled by Voucher Inventory Service)
- Customer identity and authentication (handled by Users Service)

## Domain Context

- **Business domain**: Fraud Prevention / Risk Management
- **Platform**: Continuum
- **Upstream consumers**: Orders Service, internal tools querying fraud status
- **Downstream dependencies**: Signifyd, Riskified, Orders Service, Deal Catalog Service, Goods Inventory Service, Incentive Service, M3 Places Service, M3 Merchant Service, Users Service, Voucher Inventory Service, Appointment Engine, Bhuvan, Kill Bill Payments, Taxonomy V2, TPIS

## Stakeholders

| Role | Description |
|------|-------------|
| Risk Platform team | Owns development and operation of the service |
| Commerce / Orders team | Primary upstream consumer; relies on fraud decisions before order fulfillment |
| Finance / Payments team | Receives fraud signals that affect charge and refund decisions |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | — | Inventory |
| Framework | Ruby on Rails | — | Inventory |
| Runtime | Ruby / Rails | — | Inventory |
| Build tool | Bundler | — | Inventory |
| Package manager | Bundler | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Rails | — | http-framework | Web framework and ORM foundation |
| Sidekiq | — | scheduling | Background job processing via Redis queue |
| ActiveRecord | — | orm | Database abstraction and persistence |
| Faraday | — | http-client | HTTP client for outbound API calls to fraud providers and internal services |
| Resque | — | scheduling | Alternative/legacy Redis-backed job queue |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
