---
service: "ugc-moderation"
title: Overview
generated: "2026-03-03"
type: overview
domain: "User Generated Content"
platform: "Continuum"
team: "Moderation Tool — ugc-dev@groupon.com"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2020 (strict mode)"
  framework: "Express / itier-server"
  framework_version: "^3.16.0 / ^7.7.2"
  runtime: "Node.js"
  runtime_version: "^16.13.0"
  build_tool: "Webpack ^4.34.0"
  package_manager: "npm >=6"
---

# UGC Moderation Tool Overview

## Purpose

UGC Moderation is an internal web application that provides authorized Groupon staff with a centralized interface to review, moderate, and manage User-Generated Content (UGC). It covers tips/merchant feedback, user images, user videos, review ratings, and merchant UGC data transfers. The tool enforces role-based access via Okta usernames to ensure only approved personnel can perform destructive or write actions.

## Scope

### In scope

- Searching, viewing, and deleting merchant tips and reported tips (flagged content)
- Reviewing, accepting, and rejecting user-submitted images with reason codes
- Reviewing and accepting or rejecting user-submitted videos
- Updating review ratings (score, reason, case ID) for merchant feedback
- Looking up aggregated UGC data for a merchant (tips count, recommendations)
- Transferring UGC associations from one merchant to another
- Opt-out of content for a merchant entity
- Role-based access control (general admin vs. image admin) enforced by Okta username

### Out of scope

- UGC ingestion or submission (handled by `continuumUgcService`)
- Merchant data management (owned by `m3_merchant_service`)
- Deal/groupon data management (owned by Groupon V2 API)
- Consumer-facing display of UGC
- Automated moderation or ML-based content filtering

## Domain Context

- **Business domain**: User Generated Content (UGC)
- **Platform**: Continuum (internal tools)
- **Upstream consumers**: Human operators (AppOps, Legal, CoreApps teams) via web browser; access is Okta-username-gated
- **Downstream dependencies**: `continuumUgcService` (UGC API for all read/write UGC operations), `m3_merchant_service` (merchant profile lookup), Groupon V2 API (deal data), Memcached (taxonomy caching)

## Stakeholders

| Role | Description |
|------|-------------|
| UGC Dev Team (ugc-dev@groupon.com) | Service owners; responsible for development and deployment |
| AppOps | Primary operators using the moderation interface |
| Legal | Uses the tool to act on legal content removal requests |
| CoreApps | Supports access provisioning and merchant transfer operations |
| SRE | On-call escalation via PagerDuty (P057HSW) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (Node.js, strict mode) | ES2020 | `core/routes.js`, `modules/**/*.js` |
| Framework | Express | ^3.16.0 | `package.json` |
| Server framework | itier-server | ^7.7.2 | `package.json` |
| Runtime | Node.js | ^16.13.0 | `package.json` engines, `.nvmrc` |
| Build tool | Webpack | ^4.34.0 | `package.json` devDependencies |
| Package manager | npm | >=6 | `package.json` scripts |
| Container base | alpine-node16.15.0 | 2022.05.23 | `Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `itier-server` | ^7.7.2 | http-framework | itier application server / process manager |
| `express` | ^3.16.0 | http-framework | HTTP routing and middleware |
| `keldor` | ^7.3.9 | http-framework | Groupon internal app framework (config, crash handling) |
| `keldor-config` | ^4.23.2 | configuration | CSON-based layered configuration loader |
| `itier-ugc-client` | ^6.7.0 | http-client | Client library for `continuumUgcService` API calls |
| `itier-merchant-data-client` | ^1.7.3 | http-client | Client library for `m3_merchant_service` merchant lookups |
| `itier-groupon-v2-client` | ^4.2.5 | http-client | Client library for Groupon V2 deal data |
| `itier-instrumentation` | ^9.13.4 | metrics | Wavefront / Telegraf metrics instrumentation |
| `itier-tracing` | ^1.6.1 | metrics | Distributed tracing support |
| `itier-feature-flags` | ^2.2.2 | configuration | Runtime feature flag evaluation |
| `gofer` | ^2.1.0 | http-client | HTTP service client base library |
| `hogan.js` | ^3.0.2 | ui-framework | Mustache HTML template rendering |
| `bluebird` | ^3.3.4 | async | Promise library |
| `validator` | ^5.1.0 | validation | Input validation (UUID checks for merchant IDs) |
| `csurf` | ^1.6.4 | auth | CSRF token protection for POST routes |
