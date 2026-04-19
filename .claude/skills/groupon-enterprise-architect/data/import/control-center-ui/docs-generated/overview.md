---
service: "control-center-ui"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Dynamic Pricing / Commerce Management"
platform: "continuum"
team: "Commerce Management / Pricing"
status: active
tech_stack:
  language: "JavaScript / CoffeeScript"
  language_version: "ES5 / CoffeeScript"
  framework: "Ember.js"
  framework_version: "1.13.6"
  runtime: "Node.js"
  runtime_version: "0.12"
  build_tool: "Ember CLI 1.13.8"
  package_manager: "npm"
---

# Control Center UI Overview

## Purpose

Control Center UI is an internal Groupon tool that enables commerce and pricing teams to manage dynamic pricing, create and modify sales, and control deal pricing at scale. It provides two primary features — Sale Builder for constructing and publishing sale events, and Price Changer for adjusting prices across deals and divisions — through a client-side Ember.js SPA. All pricing and sale operations are persisted via the DPCC Service and the Pricing Control Center Jtier Service backends.

## Scope

### In scope

- Manual sale creation and editing via the Sale Builder feature (`/manual-sale/*`)
- Browsing and managing existing sales (`/sale/*`)
- Bulk sale data upload via CSV/file ingestion (`/sale-uploader/*`)
- Deal and division search for sale assignment (`/search/*`)
- Price adjustment workflows via the Price Changer feature
- Division-level deal management
- SSO authentication via Doorman

### Out of scope

- Customer-facing pricing display (owned by storefront services)
- Automated algorithmic pricing decisions (owned by pricing engine services)
- Merchant-facing deal creation (owned by merchant-center-web / UMAPI)
- Voucher management and redemption (owned by commerce services)

## Domain Context

- **Business domain**: Dynamic Pricing / Commerce Management
- **Platform**: continuum
- **Upstream consumers**: Internal Groupon pricing and commerce operations staff (human users)
- **Downstream dependencies**: DPCC Service (`/__/proxies/dpcc-service/v1.0/sales`), Pricing Control Center Jtier Service (`/__/proxies/pccjt-service`), Doorman SSO

## Stakeholders

| Role | Description |
|------|-------------|
| Pricing Analyst | Primary user; creates and modifies sales and prices via Sale Builder and Price Changer |
| Commerce Operations | Manages bulk sale uploads and division-level deal configurations |
| Engineering | Maintains application; manages CI/CD and backend proxy configuration |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript / CoffeeScript | ES5 / CoffeeScript | package.json |
| Framework | Ember.js | 1.13.6 | package.json |
| Runtime | Node.js | 0.12 | package.json |
| Build tool | Ember CLI | 1.13.8 | package.json |
| Package manager | npm | | package.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| ember-data | 1.13.9 | orm | Ember.js model layer and in-memory data store |
| jquery | 1.11.3 | http-framework | DOM manipulation and AJAX request foundation |
| jquery-ui | 1.11.4 | ui-framework | Interactive UI widgets (drag/drop, datepicker, etc.) |
| lodash | 4.5.1 | serialization | Utility functions for data manipulation |
| moment | 2.10.5 | serialization | Date/time parsing and formatting for sale scheduling |
| nouislider | 8.0.1 | ui-framework | Range slider for price adjustment UI |
| papaparse | 4.1.2 | serialization | CSV parsing for bulk sale upload feature |
| aws-sdk | 2.307.0 | db-client | AWS SDK (likely for S3 file upload in sale-uploader feature) |
| express | 4.13.1 | http-framework | Node.js dev/test server |
| ember-cli-qunit | 0.3.15 | testing | Ember unit and integration test runner |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
