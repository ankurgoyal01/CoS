---
service: "mvrt"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Voucher Redemption / Merchant Operations (EMEA)"
platform: "Continuum (ITier)"
team: "MVRT"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "Node.js ^14.15.1"
  framework: "itier-server / Express"
  framework_version: "itier-server ^7.14.2 / express ^4.21.2"
  runtime: "Node.js"
  runtime_version: "14.17.0 (Alpine Docker base)"
  build_tool: "webpack ^5.101.0"
  package_manager: "npm"
---

# MVRT Overview

## Purpose

MVRT (Multi-Voucher Redemption Tool) is Groupon's internal web application used by merchant partner and customer service teams to search, inspect, and redeem Groupon vouchers in bulk on behalf of EMEA merchants. It provides both an online (interactive) search-and-redeem workflow and an offline batch processing mode that handles large code sets asynchronously, delivering results by email with downloadable XLSX/CSV reports. MVRT is SOX in-scope and operates against Continuum platform services for voucher inventory, deal catalog, and merchant data.

## Scope

### In scope

- Online multi-voucher search by unit ID, customer code, security code, Salesforce ID, product Salesforce ID, or merchant ID
- Bulk online redemption of vouchers (normal and forced/managerial redemption modes)
- Offline batch search for large code sets (up to 300,000 codes), with results uploaded to AWS S3 and delivered by email
- XLSX and CSV report generation from search results
- Okta-based authentication and LDAP/Conveyor group-based authorization per country
- Per-country access control for 14 EMEA active countries (FR, DE, IT, UK, ES, IE, BE, AE, NL, PL, AU, NZ, JP, QC)
- Scheduled background job (every minute) to process queued offline search requests
- Download endpoint for offline reports stored in AWS S3

### Out of scope

- Voucher issuance, creation, or listing for consumer-facing purposes
- Merchant onboarding or deal creation
- Non-EMEA redemption workflows (US/NA handled by other tooling)
- Consumer-facing voucher display or redemption flows

## Domain Context

- **Business domain**: Voucher Redemption / Merchant Operations (EMEA)
- **Platform**: Continuum (ITier)
- **Upstream consumers**: Groupon EMEA merchant partner team staff and customer service agents (via internal Okta-authenticated browser sessions)
- **Downstream dependencies**: `continuumVoucherInventoryService` (search and redemption), `continuumDealCatalogService` (deal/product metadata), `continuumM3MerchantService` (merchant details), `apiProxy` (outbound service routing), Rocketman (transactional email), AWS S3 (offline file storage), layout-service (page chrome)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | khsingh — primary owner, MVRT team |
| MVRT Team | agondane, akesarwani, djogi, prashkumar, ssaharawat, swjha |
| Contact | mvrt-team@groupon.com |
| On-call | PagerDuty: PEGTTFB |
| Slack | CG3QC2NR1 |
| Criticality Tier | T3 (SOX in-scope, PCI) |
| SLA | TP50 page load 5 s; TP95 page load 12 s |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (Node.js) | ^14.15.1 | `package.json` engines |
| Framework | itier-server | ^7.14.2 | `package.json` dependencies |
| HTTP layer | Express | ^4.21.2 | `package.json` dependencies |
| Runtime image | Alpine Node.js | 14.17.0 | `Dockerfile` |
| Build tool | webpack | ^5.101.0 | `package.json` devDependencies |
| Package manager | npm | — | `package.json`, `.npmrc` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `itier-server` | ^7.14.2 | http-framework | ITier application server bootstrap and cluster management |
| `express` | ^4.21.2 | http-framework | HTTP routing and middleware |
| `keldor` | ^7.3.9 | http-framework | Controller/responder abstraction for ITier apps |
| `@grpn/voucher-inventory-client` | ^1.1.2 | db-client | Client for Voucher Inventory Service (Candler) search and redemption |
| `@grpn/deal-catalog-client` | ^1.1.3 | db-client | Client for Deal Catalog Service — deal/product lookup |
| `itier-merchant-data-client` | ^1.7.3 | db-client | Client for M3 Merchant Service — merchant detail lookup |
| `@grpn/rocketman-client` | ^1.0.7 | message-client | Transactional email dispatch via Rocketman |
| `aws-sdk` | ^2.1692.0 | db-client | AWS S3 operations for offline file storage |
| `s3-client` | ^4.4.2 | db-client | High-level S3 upload/download wrapper |
| `itier-user-auth` | ^7.0.0 | auth | Okta-based user authentication |
| `itier-tracing` | ^1.9.1 | logging | Structured trace/log emission (Steno/Splunk) |
| `itier-instrumentation` | ^9.18.0 | metrics | Wavefront metrics instrumentation |
| `node-schedule` | ^1.3.3 | scheduling | Cron-based offline job scheduler (every minute) |
| `exceljs` | ^4.4.0 | serialization | XLSX report generation from voucher search results |
| `fast-csv` | ^2.5.0 | serialization | CSV report generation |
| `lodash` | ^4.17.21 | validation | Utility functions (duplicate code detection, data transforms) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
