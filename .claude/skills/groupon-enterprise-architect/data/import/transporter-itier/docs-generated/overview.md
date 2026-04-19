---
service: "transporter-itier"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Salesforce Integration"
platform: "Continuum"
team: "Salesforce Integration"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2021"
  framework: "ITier"
  framework_version: "itier-server ^7.7.3"
  runtime: "Node.js"
  runtime_version: "^16.13.0"
  build_tool: "Webpack"
  build_tool_version: "^5.72.0"
  package_manager: "npm"
---

# Transporter I-Tier Overview

## Purpose

Transporter I-Tier is an internal Groupon web application that allows Salesforce Integration team members and authorised Groupon employees to perform bulk data operations (insert, update, delete) against Salesforce objects by uploading CSV files. It delegates all backend processing and Salesforce connectivity to `transporter-jtier`, acting as a user-facing portal that handles file staging, job tracking, and OAuth-based authentication. It also provides a read-only view of Salesforce object data for internal inspection purposes.

## Scope

### In scope

- Browser-based UI for uploading CSV files targeting supported Salesforce objects
- Streaming CSV file proxy to the transporter-jtier backend via `/jtier-upload-proxy`
- Salesforce OAuth2 authorization flow initiation and callback handling at `/oauth2/callback`
- Paginated job list display with filters (action, object, user, status) at `/`
- Individual job detail view at `/job-description`
- Read-only Salesforce object browser at `/sfdata` and `/sfdata/{object}/{objectId}`
- Download of S3-hosted source, success, and error CSV files via jtier proxy at `/get-aws-csv-file`
- User validation against the jtier backend before granting upload access

### Out of scope

- Direct Salesforce API calls (delegated entirely to transporter-jtier)
- Salesforce record data storage (transporter-jtier owns all persistence)
- Batch processing or scheduling of Salesforce jobs
- Public consumer-facing features (internal tool only)

## Domain Context

- **Business domain**: Salesforce Integration
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon employees (Salesforce Integration team and other business users) accessing via web browser
- **Downstream dependencies**: `transporter-jtier` (HTTP, all backend operations and Salesforce data); Salesforce (HTTPS/OAuth2, OAuth login redirect only)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | dbertelkamp — Salesforce Integration team |
| Engineering Team | Salesforce Integration — sfint-dev@groupon.com |
| SRE / Alerts | sfint-dev-alerts@groupon.com |
| PagerDuty Service | https://groupon.pagerduty.com/services/PLUGT8Z |
| Primary Users | Internal Groupon employees performing Salesforce bulk data tasks |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | ES2021 | `package.json` |
| Framework | ITier (itier-server) | ^7.7.3 | `package.json` dependencies |
| Runtime | Node.js | ^16.13.0 | `package.json` engines |
| Build tool | Webpack | ^5.72.0 | `package.json` devDependencies |
| Package manager | npm | 6+ | `README.md` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `itier-server` | ^7.7.3 | http-framework | Core ITier application server and request lifecycle |
| `itier-routing` | ^5.1.8 | http-framework | Route definitions and module dispatch |
| `preact` | ^10.5.13 | ui-framework | Server-rendered and hydrated UI components |
| `@grpn/hydration` | ^2.1.3 | ui-framework | Client-side hydration of Preact server-rendered pages |
| `phy` | ^4.2.6 | ui-framework | Hyperscript helper for Preact rendering |
| `gofer` | ^5.2.0 | http-client | HTTP client used to call transporter-jtier APIs |
| `jsforce` | ^1.10.1 | auth | Salesforce OAuth2 flow construction and authorization URL generation |
| `multer` | ^1.4.2 | http-framework | In-memory multipart file handling for the CSV upload proxy |
| `axios` | ^0.21.1 | http-client | Browser-side HTTP POST for CSV file submission to `/jtier-upload-proxy` |
| `papaparse` | ^5.3.0 | serialization | Client-side CSV parsing and row counting before upload |
| `keldor` | ^7.3.7 | configuration | Runtime configuration loading via keldor config system |
| `keldor-config` | ^4.19.0 | configuration | Config-source-aware settings management |
| `itier-tracing` | ^1.6.1 | logging | Distributed tracing spans (used in sf-readonly and jtier client modules) |
| `itier-instrumentation` | ^9.10.4 | metrics | Application metrics instrumentation |
| `js-yaml` | ^4.1.0 | serialization | YAML secrets file parsing for Salesforce OAuth2 credentials |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `package.json` for a full list.
