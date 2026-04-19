---
service: "merchant-booking-tool"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchant Booking and Reservation Management"
platform: "Continuum"
team: "Continuum Merchant Experience"
status: active
tech_stack:
  language: "JavaScript"
  language_version: ""
  framework: "Preact"
  framework_version: ""
  runtime: "Node.js"
  runtime_version: ""
  build_tool: "I-tier build pipeline"
  package_manager: "npm"
---

# Merchant Booking Tool Overview

## Purpose

The Merchant Booking Tool is an I-tier web application within the Continuum Platform that provides merchants with a self-service interface for managing bookings and reservations. It renders server-side Preact pages, orchestrates read/write operations against the Universal Merchant API booking service, and exposes proxy and authentication helper endpoints. The tool bridges the merchant-facing web experience with backend booking-service capabilities, supporting workflows such as reservation management, calendar synchronization, campaign administration, workshop scheduling, and staff profile management.

## Scope

### In scope

- Serving merchant booking and reservation management web pages (web and mobile web)
- Rendering server-side Preact page composition via I-tier action handlers
- Routing and handling OpenAPI-defined routes for the merchant booking domain
- Reading and writing booking data through the Merchant API Client Adapter
- Proxying selected API calls through the Proxy Controller to the upstream booking service
- Bootstrapping Inbenta support authentication tokens for embedded support flows
- Orchestrating Google Calendar sync authentication via OAuth 2.0
- Rendering merchant shell/layout via the Layout Service

### Out of scope

- Core booking business logic (owned by the Universal Merchant API / booking service)
- Calendar availability computation (handled by Continuum Availability Engine and Calendar Service)
- Deal/offer management (handled by Merchant Deal Management)
- Merchant onboarding and lifecycle (handled by Merchant Lifecycle Service)
- Consumer-facing booking flows (handled by consumer-side Continuum services)

## Domain Context

- **Business domain**: Merchant Booking and Reservation Management
- **Platform**: Continuum
- **Upstream consumers**: Merchants accessing the tool via web browser (web and mobile web entry points)
- **Downstream dependencies**: `continuumUniversalMerchantApi` (booking service data), `continuumLayoutService` (merchant shell rendering), `googleOAuth` (calendar sync authentication), Inbenta (support knowledge — not in federated model)

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant | End user who books, views, and manages reservations and related business data through the tool |
| Continuum Merchant Experience Team | Owns development, operation, and evolution of the service |
| Booking Service Team | Owns the upstream `continuumUniversalMerchantApi` that provides booking data |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | — | architecture DSL: `Node.js, Preact, I-tier` |
| UI Framework | Preact | — | architecture DSL: component technology annotation |
| Runtime | Node.js | — | architecture DSL: container technology field |
| Build tool | I-tier build pipeline | — | architecture DSL: container description |
| Package manager | npm | — | Standard for Node.js / I-tier apps |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Preact | — | ui-framework | Server-side rendered UI component rendering for merchant booking pages |
| Gofer | — | http-framework | HTTP client used by the Proxy Controller to forward requests to upstream booking service base URL |
| node-fetch | — | http-framework | HTTP client used by the Inbenta Support Client to request support authentication tokens |
| Merchant API Client | — | http-framework | Structured client for calling Universal Merchant API booking-service endpoints |
| OpenAPI route definitions | — | http-framework | Declares the route surface of the I-tier web application |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
