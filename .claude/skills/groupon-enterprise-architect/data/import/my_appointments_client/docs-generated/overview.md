---
service: "my_appointments_client"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Online Booking / My Reservations"
platform: "Continuum"
team: "Online Booking"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "^16.13.0 (Node.js)"
  framework: "Express"
  framework_version: "^4.14.0"
  runtime: "Node.js"
  runtime_version: "^16.13.0"
  build_tool: "Webpack"
  package_manager: "npm >=8.0.0"
---

# My Appointments Client Overview

## Purpose

My Appointments Client (internally named `my_reservations`) is a Node.js I-Tier application that enables Groupon customers to view, create, reschedule, and cancel their service reservations and appointments. It serves both a mobile webview interface and a JSON REST API consumed by embedded booking widgets. The service acts as an orchestration layer, aggregating data from the Online Booking API, Groupon V2 API, and geodetails services to present a unified reservation management experience.

## Scope

### In scope

- Rendering mobile webview pages for post-purchase booking and reservation management (`/mobile-reservation/*`)
- Serving Preact-based booking widget JavaScript and CSS assets via the JS API
- Exposing REST endpoints for reservation CRUD operations (create, read, update, cancel)
- Exposing REST endpoints for option availability and settings lookups
- Exposing REST endpoints for deal, groupon, order-status, and user lookups
- Generating iCalendar (`.ics`) event files for reservation calendar exports
- Encrypting URL parameters for secure deep-linking
- Routing authenticated users from `/users/:userId/reservations` to My Groupons

### Out of scope

- Actual reservation persistence and business logic (handled by `continuumAppointmentsEngine`)
- Groupon purchase and voucher management (handled by `continuumApiLazloService`)
- Merchant geolocation data storage (handled by `continuumBhuvanService`)
- Page chrome and mobile layout composition (handled by `continuumLayoutService`)
- Authentication token issuance (handled by `itier-user-auth` / Groupon auth stack)

## Domain Context

- **Business domain**: Online Booking / My Reservations
- **Platform**: Continuum
- **Upstream consumers**: Groupon mobile apps (via webview), Groupon.com web frontend embedding the JS booking widget, Hybrid Boundary routing layer
- **Downstream dependencies**: `continuumAppointmentsEngine` (reservation operations), `continuumApiLazloService` (Groupon V2 data), `continuumBhuvanService` (geodetails), `continuumLayoutService` (remote layout), logging stack, metrics stack

## Stakeholders

| Role | Description |
|------|-------------|
| Service owner | rdownes (Online Booking team) |
| Engineering team | Online Booking (onlinebooking-devteam@groupon.com) |
| Alerts notify | booking-engine-frontend-alerts@groupon.com |
| PagerDuty | https://groupon.pagerduty.com/services/P05U3KD |
| Slack channel | CF9U0DPC3 |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (Node.js) | ^16.13.0 | `package.json` engines |
| Framework | Express | ^4.14.0 | `package.json` dependencies |
| Application server | itier-server | ^7.9.1 | `package.json` dependencies |
| Build tool | Webpack | ^4.44.2 | `package.json` devDependencies |
| Package manager | npm | >=8.0.0 | `package.json` engines |
| Container base | alpine-node16.15.0 | 2022.05.23 | `Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `express` | ^4.14.0 | http-framework | HTTP server and routing |
| `itier-server` | ^7.9.1 | http-framework | Groupon I-Tier application server wrapper |
| `preact` | ^10.5.13 | ui-framework | Server-side and client-side booking widget rendering |
| `online-booking-service-client` | ^6.9.2 | http-client | REST client for `continuumAppointmentsEngine` (reservations, availability) |
| `itier-groupon-v2-client` | ^4.2.5 | http-client | REST client for `continuumApiLazloService` (groupons, deals, users, orders) |
| `itier-geodetails-v2-client` | ^2.6.5 | http-client | REST client for `continuumBhuvanService` (merchant geolocation) |
| `remote-layout` | ^10.12.1 | http-client | Fetches mobile layout composition from `continuumLayoutService` |
| `itier-user-auth` | ^8.1.0 | auth | User authentication token extraction and login-redirect middleware |
| `csurf` | ^1.6.4 | auth | CSRF token generation and validation |
| `itier-feature-flags` | ^3.2.0 | configuration | Runtime feature flag evaluation |
| `itier-localization` | ^11.0.3 | i18n | Locale detection and i18n string resolution |
| `itier-instrumentation` | ^9.13.4 | metrics | Request metrics instrumentation |
| `itier-tracing` | ^1.6.1 | logging | Structured request tracing |
| `keldor-config` | ^4.23.2 | configuration | Environment-aware CSON configuration loading |
| `date-fns` | ^2.18.0 | utility | Date manipulation for reservation time handling |
| `gofer` | 3.7.4 | http-client | Low-level HTTP service client base |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
