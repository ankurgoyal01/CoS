---
service: "bling"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Finance & Accounting"
platform: "continuum"
team: "Finance Platform"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "Node.js 6.9.4"
  framework: "Ember.js"
  framework_version: "0.2.7"
  runtime: "Node.js 6.9.4 / Nginx"
  runtime_version: "6.9.4"
  build_tool: "Ember CLI"
  package_manager: "Ember CLI 0.2.7"
---

# bling Overview

## Purpose

bling is Groupon's internal single-page application (SPA) for finance and accounting operations on the Continuum platform. It provides a browser-based UI for finance staff to manage invoices, track contracts, process payments, handle paysource files, and perform batch search operations. All data is fetched and mutated through the Accounting Service backend; bling itself is a stateless client-side application with no own data store.

## Scope

### In scope

- Invoice listing, viewing, and approval workflow management
- Contract line item viewing and management
- Payment processing and payment batch management
- Paysource file upload and tracking
- User authentication via Okta/OAuth through the Hybrid Boundary proxy
- Batch search and system error review operations
- File download and management via the File Sharing Service

### Out of scope

- Accounting business logic and data persistence (handled by Accounting Service)
- Invoice generation and creation (handled upstream by billing systems)
- Vendor payment disbursement execution (handled by Accounting Service and NetSuite)
- Salesforce and NetSuite data entry (bling provides read views; source-of-record operations stay in those systems)
- Merchant-facing operations (handled by Merchant Center)

## Domain Context

- **Business domain**: Finance & Accounting
- **Platform**: Continuum
- **Upstream consumers**: Groupon finance and accounting staff (internal browser users)
- **Downstream dependencies**: Accounting Service (core backend), File Sharing Service, Hybrid Boundary (OAuth/Okta proxy)

## Stakeholders

| Role | Description |
|------|-------------|
| Finance staff | Primary end users; perform invoice approvals, payment processing, and paysource file uploads |
| Accounting team | Primary end users; manage contracts and financial records |
| Finance Platform engineers | Developers and maintainers of the bling application |
| Continuum platform team | Owners of the Accounting Service backend |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | Node.js 6.9.4 | `package.json` |
| Framework | Ember.js | 0.2.7 | `package.json`, `bower.json` |
| Runtime | Node.js | 6.9.4 | `.nvmrc`, `package.json` |
| Build tool | Ember CLI | 0.2.7 | `package.json` |
| Package manager | npm / Ember CLI | 0.2.7 | `package.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| ember-cli | 0.2.7 | http-framework | Ember.js build system and development server |
| ember-select-2 | 1.3.0 | ui-framework | Select2-based dropdown component for filter/search UI |
| ember-table | 0.5.0 | ui-framework | High-performance table component for invoice and contract list views |
| ember-ajax | 2.3.2 | http-framework | AJAX service for Ember.js API calls to Accounting Service |
| http-proxy | 1.11.1 | http-framework | Node.js reverse proxy for development server API proxying |
| stylus | 0.54.6 | ui-framework | CSS preprocessor for application styles |
| broccoli-asset-rev | 2.0.0 | http-framework | Asset fingerprinting for cache-busting on Nginx deployment |
| es5-shim | 4.1.5 | http-framework | ES5 compatibility shim for older browser support |
| ember-cli-qunit | 0.3.9 | testing | QUnit-based test runner integrated with Ember CLI |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
