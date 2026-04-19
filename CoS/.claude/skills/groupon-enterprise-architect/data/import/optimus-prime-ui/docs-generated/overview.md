---
service: "optimus-prime-ui"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data & Analytics Tools"
platform: "Continuum"
team: "DnD Tools"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2022"
  framework: "Vue"
  framework_version: "2.7.14"
  runtime: "Node.js"
  runtime_version: ">=18.13.0"
  build_tool: "Vite"
  build_tool_version: "4.1.4"
  package_manager: "pnpm >=7"
---

# Optimus Prime UI Overview

## Purpose

Optimus Prime UI is the browser-based front-end for the Optimus Prime ETL platform, enabling data engineers and analysts at Groupon to create, configure, schedule, and monitor ETL pipeline jobs in the cloud. It is a fully rebuilt replacement for Legacy Optimus, providing a modern interface for defining multi-step data movement workflows across heterogeneous data connections. The UI operates entirely as a single-page application, communicating with the `optimus-prime-api` backend over HTTPS.

## Scope

### In scope

- Authoring and editing ETL jobs composed of ordered, dependency-linked steps (SQL, DBDataMover, RestAPITrigger, EmailSQLReport)
- Managing cron-scheduled and on-demand job execution
- Browsing and filtering job run history with step-level log access
- Managing database and file-transfer connections (MySQL, Teradata, SFTP, PostgreSQL, Hive, TDJDBC, SQLServer, Oracle, S3, Snowflake, GoogleSheet, HDFS)
- Managing workspaces and workspace-level membership and analytics
- Running ad-hoc data fetcher operations (DBDATAMOVER source to GoogleSheet or S3 target)
- Running ad-hoc data loader operations (file or GoogleSheet source to database target)
- Viewing watch-list dashboards and upcoming schedule summaries
- Collecting and forwarding user interaction, performance, and error telemetry to Google Analytics

### Out of scope

- ETL job execution engine (handled by `optimus-prime-api` and its underlying scheduler)
- Data storage and pipeline orchestration (handled by backend services)
- User identity and authentication (handled by the Groupon identity platform; user info injected via nginx headers)
- Email delivery for job success/failure notifications (handled by backend)

## Domain Context

- **Business domain**: Data & Analytics Tools — internal tooling for data movement and ETL pipeline automation
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon data engineers and analysts accessing the UI through a browser
- **Downstream dependencies**: `optimus-prime-api` (all domain data via `/api/v2`), Google Analytics (telemetry via gtag)

## Stakeholders

| Role | Description |
|------|-------------|
| Team Owner | DnD Tools team (apadiyar, cwright, kyim, nhassanzadeh) |
| Primary Users | Internal Groupon data engineers and analysts creating ETL jobs |
| On-call / SRE | PagerDuty service PTJKFRO; alert email optimus-prime@groupon.pagerduty.com |
| Mailing list | dnd-tools@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | ES2022 (ESM) | `package.json` `"type": "module"` |
| UI Framework | Vue | 2.7.14 | `package.json` dependencies |
| Component Library | Vuetify | 2.6.14 | `package.json` dependencies |
| Runtime | Node.js | >=18.13.0 | `package.json` engines; `Dockerfile` `FROM node:18-alpine` |
| Build tool | Vite | 4.1.4 | `package.json` devDependencies |
| Package manager | pnpm | >=7 (9.12.1 in Docker) | `package.json` engines; `Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `vue-router` | 3.1.6 | ui-framework | Client-side SPA routing across all application views |
| `pinia` | 2.0.34 | state-management | Centralized reactive store for jobs, connections, workspaces, datafetchers, dataloaders |
| `axios` | 1.1.3 | http-framework | HTTP client for all requests to the `optimus-prime-api` backend |
| `vuetify` | 2.6.14 | ui-framework | Material Design component library for layout, forms, tables, dialogs |
| `echarts` | 5.3.2 | ui-framework | Charting library for run-history and analytics charts |
| `codemirror` | 5.60.0 | ui-framework | In-browser SQL and code editor for job step authoring |
| `drawflow` | 0.0.40 | ui-framework | Visual DAG editor for composing job step dependency graphs |
| `cron-parser` | 2.13.0 | scheduling | Parses cron expressions to compute upcoming schedule times |
| `cronstrue` | 1.88.0 | scheduling | Converts cron expressions to human-readable descriptions |
| `dayjs` | 1.11.7 | serialization | Date/time formatting and manipulation across UI filters |
| `web-vitals` | 2.1.0 | metrics | Collects Core Web Vitals (LCP, FID, CLS) and forwards to Google Analytics |
| `msw` | 0.26.2 | testing | Mock Service Worker for local API mocking during development/test |
| `animate.css` | 3.7.2 | ui-framework | CSS animation library for page transitions |
| `@mdi/font` | 7.1.96 | ui-framework | Material Design icon font used throughout the UI |
