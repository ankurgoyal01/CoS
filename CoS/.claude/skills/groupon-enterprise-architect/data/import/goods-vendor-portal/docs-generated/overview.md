---
service: "goods-vendor-portal"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Goods / Merchant Operations"
platform: "Continuum"
team: "Goods/Sox"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES6"
  framework: "Ember.js"
  framework_version: "3.14.0"
  runtime: "Nginx"
  runtime_version: "stable"
  build_tool: "ember-cli"
  build_tool_version: "3.14.0"
  package_manager: "npm"
---

# Goods Vendor Portal Overview

## Purpose

The Goods Vendor Portal is a merchant-facing single-page application that provides a unified web interface for goods vendors to manage every aspect of their relationship with Groupon. It enables merchants to maintain their product catalog, create and track deals and promotions, manage contracts and co-op agreements, handle their vendor profile, and view business analytics and insights. All data access is delegated to the GPAPI (Groupon Goods Platform API) backend via an Nginx-proxied gateway.

## Scope

### In scope

- Merchant authentication and session management
- Product catalog browsing, creation, and editing
- Deal and promotion creation and lifecycle management
- Contract viewing and co-op agreement management
- Vendor profile self-service (addresses, contacts, banking)
- Business analytics and insights reporting
- File upload and download for catalog and deal assets
- Support request submission
- Feature flag-driven UI capability toggling
- Pricing management for products and deals

### Out of scope

- Backend business logic and data persistence (owned by GPAPI)
- Order processing and fulfillment workflows (owned by Continuum core services)
- Consumer-facing storefront (separate system)
- Financial settlement calculations (owned by `continuumAccountingService`)
- Vendor onboarding approval workflows (handled by internal tooling)

## Domain Context

- **Business domain**: Goods / Merchant Operations
- **Platform**: Continuum
- **Upstream consumers**: Goods merchants (human users via browser); Groupon internal operations staff
- **Downstream dependencies**: GPAPI (Groupon Goods Platform API) for all data reads and writes; `continuumAccountingService` for financial data transmission

## Stakeholders

| Role | Description |
|------|-------------|
| Goods Merchant | Primary end user; manages their catalog, deals, and vendor profile through the portal |
| Groupon Internal Operations | Uses the portal for vendor support and deal management |
| Goods/Sox Team | Owns and develops the portal; responsible for SOX compliance controls in the UI |
| GPAPI Team | Owns the backend API that this portal consumes |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | ES6 | package.json |
| Framework | Ember.js | 3.14.0 | package.json (`ember-source`) |
| Runtime (build) | Node.js | 14.21 | Dockerfile / .nvmrc |
| Runtime (serve) | Nginx | stable | Dockerfile multi-stage |
| Build tool | ember-cli | 3.14.0 | package.json (`ember-cli`) |
| Package manager | npm | — | package-lock.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| ember-source | 3.14.0 | ui-framework | Core SPA framework for routing, components, and data binding |
| ember-data | 2.10.0 | orm | Model layer and adapter/serializer pattern for GPAPI communication |
| ember-cli | 3.14.0 | build-tool | Asset pipeline, live reload, and production builds |
| ember-simple-auth | 1.1.0 | auth | Session management and authenticated route enforcement |
| ember-i18n | 5.0.0 | ui-framework | Internationalization and locale-aware string rendering |
| ember-feature-flags | 2.0.1 | ui-framework | Runtime feature flag evaluation for controlled capability rollouts |
| react | 16.13.1 | ui-framework | Isolated React components embedded within the Ember application for specific UI widgets |
| chart.js | 2.8.0 | ui-framework | Data visualization library for analytics and insights dashboards |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
