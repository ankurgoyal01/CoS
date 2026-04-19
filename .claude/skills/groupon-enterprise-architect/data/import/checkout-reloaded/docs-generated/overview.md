---
service: "checkout-reloaded"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Commerce — Checkout Experience (BFF)"
platform: "Continuum"
team: "Checkout / Consumer Experience"
status: active
tech_stack:
  language: "TypeScript"
  language_version: "5.x"
  framework: "itier-server"
  framework_version: "7.14.2"
  runtime: "Node.js"
  runtime_version: "20.19.6"
  build_tool: "npm + TypeScript compiler + Webpack"
  package_manager: "npm"
---

# checkout-reloaded Overview

## Purpose

checkout-reloaded is the server-side rendered BFF (Backend for Frontend) that delivers the end-to-end checkout experience for Groupon consumers. It orchestrates cart review, pricing validation, payment processing via Adyen, and order confirmation flows across multiple downstream services. The service is stateless — it persists no data directly, delegating all state to purpose-built downstream systems.

## Scope

### In scope

- Rendering the checkout, cart review, receipt, and post-purchase pages via server-side Preact SSR
- Accepting and processing checkout form submissions (POST /checkout/submit)
- Orchestrating the payment authorization flow using the Adyen drop-in component
- Coordinating with Cart Service, Pricing Service, Order Service, and Deal Catalog during a checkout request
- Managing CSRF token validation for form submissions
- Serving health check endpoints for Kubernetes probes
- Applying runtime feature flags from Keldor to enable/disable checkout variants

### Out of scope

- Persistent storage of checkout sessions or order data (owned by downstream services via `continuumCheckoutReloadedDb`)
- Kafka or MBus event publishing (delegated to the Order Service upon order finalization)
- Payment gateway infrastructure (provided by Adyen)
- User authentication and identity management (provided by UMAPI)
- Shared site header/footer rendering (provided by Layout Service)

## Domain Context

- **Business domain**: Commerce — Checkout Experience (BFF)
- **Platform**: Continuum
- **Upstream consumers**: Groupon consumers (browsers), Groupon mobile clients via web views
- **Downstream dependencies**: Cart Service, Pricing Service, Order Service, Deal Catalog Service, Adyen Payment SDK, Auth/Identity Service (UMAPI), Layout Service, API Proxy (itier-groupon-v2-client), Keldor (feature flags)

## Stakeholders

| Role | Description |
|------|-------------|
| Checkout / Consumer Experience Team | Primary owners; responsible for feature development, on-call, and incident response |
| Commerce Platform Team | Owns downstream Order and Cart services that checkout-reloaded depends on |
| Payments Team | Owns Adyen integration configuration and merchant account settings |
| SRE / Conveyor Team | Owns Kubernetes deployment pipeline and infrastructure |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | 5.x | package.json |
| Framework | itier-server | 7.14.2 | package.json |
| Runtime | Node.js | 20.19.6 | .nvmrc / Dockerfile |
| Build tool | npm + TypeScript compiler + Webpack | — | package.json |
| Package manager | npm | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | 7.14.2 | http-framework | Express-based BFF server with SSR, routing, feature flags |
| express | 4.18.2 | http-framework | HTTP server and routing |
| preact | 10.x | ui-framework | Server-side rendering of checkout views |
| redux | 4.x | state-management | Client-side checkout state management |
| @adyen/adyen-web | 5.x | payment | Adyen payment drop-in component |
| axios | 1.x | http-client | Downstream API calls |
| itier-groupon-v2-client | latest | http-client | Groupon internal API proxy client |
| keldor-client | latest | config | Runtime feature flag client |
| winston | 3.x | logging | Structured logging |
| jest | 29.x | testing | Unit and integration tests |
| webpack | 5.x | build | Client bundle compilation |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
