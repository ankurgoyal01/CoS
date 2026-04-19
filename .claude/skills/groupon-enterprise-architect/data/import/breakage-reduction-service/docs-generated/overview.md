---
service: "breakage-reduction-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Redemption / Post-Purchase"
platform: "Continuum"
team: "Post Purchase"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2020 (Node.js ^16)"
  framework: "I-Tier"
  framework_version: "itier-server ^7.14.2"
  runtime: "Node.js"
  runtime_version: "^16"
  build_tool: "webpack"
  package_manager: "npm ^8"
---

# Breakage Reduction Service Overview

## Purpose

Breakage Reduction Service (BRS), also known as Voucher EXchange (VEX), is a Node.js I-Tier web service that orchestrates post-purchase engagement workflows for Groupon voucher holders. It evaluates the state of a user's voucher and computes which next-actions (notifications, extensions, trade-ins, reminders, etc.) should be triggered to reduce voucher breakage — that is, vouchers that expire unused. It also exposes APIs that allow consumers to schedule or retrieve reminders for individual vouchers.

## Scope

### In scope

- Computing and returning a prioritized list of voucher next-actions for post-purchase breakage reduction workflows (`/voucher/v1/next_actions`)
- Scheduling user-initiated voucher reminders via the RISE scheduler (`/remind_me_later/...`)
- Assembling campaign message content (push and in-app notifications) for downstream messaging systems (`/message/v1/content`)
- Backfilling and bulk-scheduling notification workflows via RISE
- Aggregating voucher context by orchestrating parallel calls to VIS, TPIS, Orders, Deal Catalog, Users, Merchant, Place, UGC, EPODS, AMS, and RISE
- Applying feature-flag-controlled eligibility rules for expiration extensions, trade-in windows, risk-free deals, gifting flows, and booking workflows
- Caching workflow helper state in Redis

### Out of scope

- Sending push or email notifications directly (delegated to RISE and downstream messaging services)
- Managing voucher inventory state (owned by Voucher Inventory Service / TPIS)
- Order management and payment processing (owned by the Orders service)
- Deal catalog management (owned by Deal Catalog service)
- User account management (owned by Users service)

## Domain Context

- **Business domain**: Redemption / Post-Purchase
- **Platform**: Continuum
- **Upstream consumers**: Consumer-facing web and mobile clients; internal post-purchase notification pipeline
- **Downstream dependencies**: Voucher Inventory Service (VIS), Third-Party Inventory Service (TPIS), Deal Catalog, Orders, Users, Merchant (M3), Place (M3PlaceRead), UGC, EPODS, AMS, RISE (scheduler), Appointment Engine, Redis

## Stakeholders

| Role | Description |
|------|-------------|
| Team owner | Post Purchase engineering team (ppeng@groupon.com) |
| Service owner | imaya |
| On-call / PagerDuty | brs-vex@groupon.pagerduty.com |
| Incident contact | shawshank@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (Node.js) | ^16 | `package.json` engines |
| Framework | I-Tier (itier-server) | ^7.14.2 | `package.json` dependencies |
| Runtime | Node.js | ^16 | `.nvmrc`, `Dockerfile` (alpine-node16.14.2) |
| Build tool | webpack | ^4.43.0 | `package.json` devDependencies |
| Package manager | npm | ^8 | `package.json` engines |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `itier-server` | ^7.14.2 | http-framework | Core I-Tier HTTP server and routing |
| `gofer` | ^5.2.3 | http-client | HTTP client used for all downstream service calls |
| `@grpn/graphql` | ^3.1.0 | http-client | GraphQL client for Groupon API v2 |
| `@grpn/graphql-gapi` | ^5.1.0 | http-client | GAPI GraphQL integration |
| `keldor` | ^7.3.7 | config | Multi-environment CSON configuration loader |
| `keldor-config` | ^4.19.0 | config | Configuration source resolver |
| `itier-feature-flags` | ^2.2.2 | feature-flags | Runtime feature flag evaluation |
| `redis` | ^2.8.0 | db-client | Redis client for workflow helper state |
| `itier-instrumentation` | ^9.10.4 | metrics | Wavefront/Telegraf metrics instrumentation |
| `itier-tracing` | ^1.6.1 | logging | Distributed tracing integration |
| `@grpn/preact-page` | ^2.4.2 | ui-framework | Server-side rendering with Preact |
| `preact` | ^10.5.13 | ui-framework | UI component rendering |
| `moment-timezone` | ^0.5.34 | scheduling | Timezone-aware date/time computation for workflow windows |
| `lodash` | ^4.17.15 | utility | Collection manipulation and data access helpers |
| `@pact-foundation/pact` | ^16.0.2 | testing | Pact consumer-driven contract tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `package.json` for a full list.
