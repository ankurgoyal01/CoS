---
service: "checkout-flow-analyzer"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Checkout Analytics / Internal Tooling"
platform: "Continuum"
team: "Checkout Engineering"
status: active
tech_stack:
  language: "TypeScript"
  language_version: "5"
  framework: "Next.js"
  framework_version: "15.3.0"
  runtime: "Node.js"
  runtime_version: "20"
  build_tool: "next build"
  package_manager: "pnpm"
---

# Checkout Flow Analyzer Overview

## Purpose

The Checkout Flow Analyzer is an internal Next.js web application that gives Groupon engineers a unified view of the checkout session journey across multiple log sources (PWA frontend, proxy, Lazlo backend, and orders service). It allows analysts to select a time window, browse individual browser sessions (identified by `bcookie`), and inspect event timelines, conversion rates, and platform breakdowns. The tool exists to accelerate diagnosis of checkout drop-offs, API errors, and flow anomalies without requiring direct log-system access.

## Scope

### In scope

- Time-window selection from pre-loaded CSV/ZIP log archives stored on the local filesystem
- Session browsing with pagination, full-text search, and bCookie filtering
- Per-session event timeline display (PWA events, proxy requests, Lazlo calls, order events)
- Conversion rate metrics: View-to-Attempt, Attempt-to-Success, View-to-Success rates
- Platform distribution breakdown by unique browser session
- Aggregated session statistics via optimized `bcookie_summary` files
- Authentication via Okta OIDC (or credentials provider in development mode)
- Security headers (CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy)

### Out of scope

- Real-time log ingestion or streaming — data is file-based and batch-loaded
- Writing back to any Groupon backend system
- Order management or checkout business logic
- Log collection or export from Kibana/ELK (files must be prepared and placed externally)

## Domain Context

- **Business domain**: Checkout Analytics / Internal Tooling
- **Platform**: Continuum
- **Upstream consumers**: Checkout engineers and analysts who use the UI directly in a browser
- **Downstream dependencies**: Local filesystem CSV/ZIP data files (`src/assets/data-files/`); Okta Identity Cloud (OIDC authentication)

## Stakeholders

| Role | Description |
|------|-------------|
| Checkout Engineer | Primary user — investigates checkout failures and conversion drops using session timelines |
| Checkout Analyst | Reviews top-stats dashboards and conversion metrics for trend monitoring |
| Platform Ops | Ensures Okta integration is functioning and the application is accessible |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | 5 | `package.json` devDependencies |
| Framework | Next.js (App Router) | 15.3.0 | `package.json`, `next.config.ts` |
| Runtime | Node.js | 20 | `@types/node ^20` in `package.json` |
| Build tool | next build | 15.3.0 | `package.json` scripts |
| Package manager | pnpm | — | `pnpm-lock.yaml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `react` | ^19.0.0 | ui-framework | React rendering engine for all pages and components |
| `next-auth` | ^4.24.11 | auth | Session management and Okta OIDC sign-in via NextAuth |
| `@okta/okta-auth-js` | ^7.12.1 | auth | Okta SDK used with NextAuth Okta provider |
| `papaparse` | ^5.5.2 | serialization | Streaming CSV parsing for all log file types |
| `adm-zip` | ^0.5.16 | serialization | ZIP archive extraction for compressed log files |
| `recharts` | ^2.15.2 | ui-framework | Conversion rate and session metric charts |
| `@nivo/sankey` | ^0.88.0 | ui-framework | User flow Sankey diagram visualization |
| `flowbite-react` | ^0.11.7 | ui-framework | Component library (tables, badges, modals, pagination) |
| `tailwindcss` | 3.4.1 | ui-framework | Utility-first CSS framework |
| `react-window` | ^1.8.11 | ui-framework | Virtualized list rendering for large session tables |
| `@headlessui/react` | ^2.2.2 | ui-framework | Accessible modal and dropdown primitives |
| `@testing-library/react` | ^16.3.0 | testing | Component-level unit tests |
| `jest` | ^29.5.14 | testing | Test runner (jest-environment-jsdom) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
