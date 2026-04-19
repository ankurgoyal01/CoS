---
service: "mx-reservations-app"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Merchant Reservations"
platform: "Continuum"
team: "booking-tool (booking-tool@groupon.com)"
status: active
tech_stack:
  language: "TypeScript"
  language_version: "3.7.2"
  framework: "Express"
  framework_version: "4.16.4"
  runtime: "Node.js"
  runtime_version: "10/12"
  build_tool: "Webpack"
  build_tool_version: "4.29.6"
  package_manager: "npm"
---

# MX Reservations App Overview

## Purpose

MX Reservations App is a merchant-facing web application that enables Groupon merchants to manage their reservations, bookings, workshop scheduling, and redemption workflows. It runs as a Node.js/TypeScript server delivering a React/Preact single-page application, acting as a BFF (Backend for Frontend) that proxies API calls to the backend Continuum platform services. The app provides merchants with a unified interface for all reservation lifecycle operations without owning any persistent data itself.

## Scope

### In scope

- Serving the merchant-facing SPA for reservation management
- Booking workflow: creating and managing individual reservations
- Calendar management: viewing and updating merchant availability
- Workshop scheduling: creating and managing group event sessions
- Redemption and check-in: validating and processing customer redemptions
- Proxying API requests to backend via `/reservations/api/v2/*`
- Authenticated API request construction (token handling, endpoint path substitution)
- Demo/test mode via in-process memory server adapter
- Feature flag evaluation via itier-feature-flags

### Out of scope

- Persistent data storage (stateless BFF; data lives in downstream services)
- Consumer-facing reservation UX (merchant-only)
- Payment processing (delegated to downstream services via API Proxy)
- Authentication token issuance (consumed from itier-user-auth)
- Deal/offer management (handled by Marketing Deal Service)

## Domain Context

- **Business domain**: Merchant Reservations
- **Platform**: Continuum
- **Upstream consumers**: Merchants accessing the web app directly via browser
- **Downstream dependencies**: API Proxy (`apiProxy`), Marketing Deal Service (`continuumMarketingDealService`), itier-divisions, itier-geodetails, itier-groupon-v2-client, itier-subscriptions, merchant-booking-tool library

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant | End user who books, schedules, and manages reservations through the app |
| booking-tool team | Engineering team owning development and operations (booking-tool@groupon.com) |
| Groupon Operations | Internal teams using reservation data surfaced by this app |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | 3.7.2 | package.json |
| Framework | Express | 4.16.4 | package.json |
| Runtime | Node.js | 10/12 | Dockerfile / .nvmrc |
| Build tool | Webpack | 4.29.6 | package.json |
| Package manager | npm | | package-lock.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| React | 16.9.0 | ui-framework | Primary SPA rendering framework |
| Preact | 8.4.2 | ui-framework | Lightweight React-compatible renderer for production bundle |
| itier-server | 5.35.1 | http-framework | Groupon-internal Express server wrapper with itier conventions |
| Gofer | 3.7.5 | http-framework | Groupon-internal HTTP client for downstream service calls |
| itier-user-auth | 6.1.0 | auth | Session and token management for authenticated merchant requests |
| itier-feature-flags | 1.5.0 | scheduling | Feature flag evaluation for progressive rollout control |
| keldor | 7.2.3 | http-framework | Groupon-internal service discovery / API routing library |
| styled-components | 4.2.0 | ui-framework | CSS-in-JS styling for React components |
| Jest | 24.9.0 | testing | Unit and integration test runner |
| CodeceptJS | 2.3.0 | testing | End-to-end acceptance test framework |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
