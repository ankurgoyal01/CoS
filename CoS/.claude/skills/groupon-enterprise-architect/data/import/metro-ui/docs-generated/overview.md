---
service: "metro-ui"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Merchant Self-Service / Deal Management"
platform: "Continuum"
team: "Metro Dev (metro-dev-blr@groupon.com)"
status: active
tech_stack:
  language: "TypeScript"
  language_version: "^4.9.5"
  framework: "itier-server"
  framework_version: "^7.7.2"
  runtime: "Node.js"
  runtime_version: "^14.19.1"
  build_tool: "Webpack (@grpn/mx-webpack ^2.18.0)"
  package_manager: "npm"
---

# Metro UI Overview

## Purpose

Metro UI is the merchant self-service deal creation and management interface on the Groupon platform. It provides merchants with a browser-based UI to create, draft, edit, and publish deals, including AI-assisted content generation and geo/location management. The service runs as a Node.js/itier-server application that performs server-side rendering and delegates all persistent data operations to downstream backend services.

## Scope

### In scope

- Serving the merchant deal creation and draft editing UI at `/merchant/center/draft`
- Server-side rendering of deal creation, edit, and internal workflow pages
- Orchestrating calls to Deal Management API, Geo Details Service, M3 Places Service, and Marketing Deal Service
- AI content generation proxy for deal copy (titles, descriptions) via `/v2/merchants/{id}/mdm/deals/{id}/ai/contentai`
- Deal asset upload handling via `/v2/merchants/{id}/mdm/deals/{id}/upload`
- Location and service area management for merchant places
- Browser-side analytics tag injection via Google Tag Manager
- Distributed tracing, metrics emission, and structured logging

### Out of scope

- Persistent storage of deal data (handled by `continuumDealManagementApi`)
- Deal publication approval workflows (handled by downstream deal management services)
- Merchant account management and authentication (handled by upstream identity/auth services)
- AI model training and inference (handled by the GenAI/DSSI Airflow Platform)
- Geo data ingestion and maintenance (handled by `continuumGeoDetailsService` and `continuumM3PlacesService`)

## Domain Context

- **Business domain**: Merchant Self-Service / Deal Management
- **Platform**: Continuum
- **Upstream consumers**: Merchant users via browser; internal tooling via direct URL access to `/merchant/center/draft`
- **Downstream dependencies**: `apiProxy`, `continuumDealManagementApi`, `continuumGeoDetailsService`, `continuumM3PlacesService`, `continuumMarketingDealService`, `googleTagManager`, `loggingStack`, `metricsStack`, `tracingStack`

## Stakeholders

| Role | Description |
|------|-------------|
| Metro Dev Team | Service owner and primary developer (metro-dev-blr@groupon.com) |
| Tech Lead | abhishekkumar — architecture and technical decisions |
| Merchants | End users interacting with the deal creation UI |
| Deal Operations | Internal Groupon teams using internal deal workflows |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | ^4.9.5 | package.json |
| Framework | itier-server | ^7.7.2 | package.json |
| Runtime | Node.js | ^14.19.1 | package.json, Dockerfile (alpine-node14.19.1) |
| Build tool | Webpack | @grpn/mx-webpack ^2.18.0 | package.json |
| Package manager | npm | | package-lock.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| react | ^17.0.2 | ui-framework | Component-based page rendering |
| redux | ^4.0.0 | state-management | Client-side application state |
| axios | 0.27.2 | http-framework | Outbound HTTP requests to backend services |
| draft.js | 0.11.1 | ui-framework | Rich-text editor for deal content fields |
| itier-merchant-api-client | 1.1.8 | http-framework | Typed client for merchant API endpoints |
| keldor | 7.3.7 | http-framework | itier internal service client / middleware |
| itier-instrumentation | 9.10.4 | metrics | Service metrics emission |
| itier-tracing | 1.6.2 | metrics | Distributed trace propagation |
| @dnd-kit/sortable | 8.0.0 | ui-framework | Drag-and-drop sortable UI for deal sections |
| DOMPurify | 3.2.7 | validation | Sanitization of user-provided HTML content |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
