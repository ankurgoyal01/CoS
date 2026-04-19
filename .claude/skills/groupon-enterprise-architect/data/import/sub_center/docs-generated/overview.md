---
service: "sub_center"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Email / Subscription Management"
platform: "continuum"
team: "Continuum Platform"
status: active
tech_stack:
  language: "Node.js"
  language_version: ""
  framework: "itier-server / Express (Keldor)"
  framework_version: ""
  runtime: "Node.js"
  runtime_version: ""
  build_tool: "npm"
  package_manager: "npm"
---

# Subscription Center Overview

## Purpose

sub_center is a Node.js I-Tier web application that renders subscription center pages and handles email and SMS unsubscribe flows for Groupon users. It serves as the primary user-facing interface for managing marketing communication preferences, enabling users to control which email channels and SMS alerts they receive. The service orchestrates calls to multiple Continuum backend services to read and write subscription state, evaluate feature flags, and render server-side pages.

## Scope

### In scope

- Rendering subscription center HTML pages via itier-server / Keldor templates
- Handling email unsubscribe requests for individual and bulk channel opt-outs
- Handling SMS unsubscribe flows via Twilio integration
- Managing subscription preference updates (channel-level enable/disable)
- Fetching and caching division and channel metadata from downstream services
- Evaluating feature flags to gate subscription UX features
- Sending tracking events to the Optimize Service

### Out of scope

- Storing subscription state (owned by Subscriptions Service and Groupon V2 API)
- Managing email delivery or campaign sending (handled by GSS and upstream marketing systems)
- Transactional SMS beyond weekly digest flow notifications (handled by Twilio directly)
- Geographic data resolution (delegated to GeoDetails Service)
- Page layout and navigation chrome (delegated to Remote Layout Service)

## Domain Context

- **Business domain**: Email / Subscription Management
- **Platform**: Continuum
- **Upstream consumers**: End users (browser), email unsubscribe link redirects
- **Downstream dependencies**: Groupon V2 API, GSS Service, Subscriptions Service, GeoDetails Service, Remote Layout Service, Feature Flags Service, Optimize Service, Twilio SMS, Memcached

## Stakeholders

| Role | Description |
|------|-------------|
| End User | Groupon subscriber managing their email and SMS preferences |
| Email Marketing Team | Relies on unsubscribe flows to maintain list hygiene and compliance |
| Continuum Platform Team | Owns and maintains this I-Tier web app |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Node.js (CoffeeScript handlers) | — | `architecture/models/components/subCenterWebApp.dsl` |
| Framework | itier-server / Express (Keldor) | — | `architecture/models/containers.dsl` |
| Runtime | Node.js | — | `architecture/models/containers.dsl` |
| Build tool | npm | — | Inferred from Node.js ecosystem |
| Package manager | npm | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Keldor | — | http-framework | Controller and routing layer for I-Tier apps |
| itier-render | — | ui-framework | Server-side page rendering with templates |
| itier-* clients | — | http-framework | API client integrations for Groupon services |
| Twilio SDK | — | messaging | Sends SMS messages for weekly digest flows |
| Memcached client | — | db-client | Caches division and channel metadata |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
