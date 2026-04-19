---
service: "teradata-self-service-ui"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Data & Discovery Tools"
platform: "Continuum"
team: "DnD Tools"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2017+"
  framework: "Vue.js"
  framework_version: "2.6.11"
  runtime: "Nginx"
  runtime_version: "stable-alpine"
  build_tool: "Vue CLI 4.5"
  package_manager: "Yarn"
---

# Teradata Self Service UI Overview

## Purpose

The Teradata Self Service UI (TSS UI) is a Vue.js single-page web application that provides Groupon employees with a self-service interface for creating and managing their Teradata database accounts. It replaces the legacy TSST system and is built and maintained by the DnD Tools team. The UI delegates all data operations to the `teradata-self-service-api` backend service via proxied REST calls.

## Scope

### In scope

- Displaying the authenticated user's personal Teradata account and its status (OK, LOCKED, INACTIVE, UNKNOWN)
- Displaying managed service accounts associated with the user
- Requesting creation of a new Teradata account (triggers a manager-approval workflow)
- Reactivating an existing inactive Teradata account
- Updating (resetting) a Teradata account password
- Viewing and managing pending account-creation approval requests (for managers)
- Viewing the full history of past requests
- GMS (Global Merchant Services) employee restriction enforcement
- Google Analytics instrumentation for user interactions, API timing, and web vitals

### Out of scope

- Teradata account provisioning logic (handled by `teradata-self-service-api`)
- Manager email notifications (handled by `teradata-self-service-api`)
- Jira ticket creation for account requests (handled by `teradata-self-service-api`)
- Authentication and SSO (handled upstream by Okta/corporate identity provider via request headers)

## Domain Context

- **Business domain**: Data & Discovery Tools — internal tooling for data platform access management
- **Platform**: Continuum (GCP/Kubernetes)
- **Upstream consumers**: Groupon employees (browser) accessing via internal VPN; identity headers injected by the corporate SSO proxy
- **Downstream dependencies**: `teradata-self-service-api` (REST, proxied via Nginx), Google Analytics (HTTPS telemetry)

## Stakeholders

| Role | Description |
|------|-------------|
| Team owner | DnD Tools team (`dnd-tools@groupon.com`), owned by `vnarayanan` |
| SRE / on-call | PagerDuty service `PRFAUHJ`; Slack `#dnd-tools-ops` |
| End users | Groupon employees who need Teradata access |
| Approving managers | Managers who approve/decline new account requests |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | ES2017+ | `package.json`, `babel.config.js` |
| Framework | Vue.js | 2.6.11 | `package.json` → `"vue": "^2.6.11"` |
| UI component library | Vuetify | 2.4.0 | `package.json` → `"vuetify": "^2.4.0"` |
| State management | Vuex | 3.4.0 | `package.json` → `"vuex": "^3.4.0"` |
| Client-side routing | Vue Router | 3.2.0 | `package.json` → `"vue-router": "^3.2.0"` |
| Build tool | Vue CLI Service | 4.5.0 | `package.json` → `"@vue/cli-service": "~4.5.0"` |
| Package manager | Yarn | — | `Dockerfile` → `RUN yarn; yarn build` |
| Runtime server | Nginx | stable-alpine | `Dockerfile` (production stage) |
| Build container | Node.js | 14-alpine | `Dockerfile` → `FROM node:14-alpine` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| axios | ^0.24.0 | http-client | HTTP calls to `teradata-self-service-api` via API client |
| vue-router | ^3.2.0 | routing | Client-side SPA routing for Accounts, Requests, History views |
| vuex | ^3.4.0 | state-management | Centralised application state (accounts, requests, user, config) |
| vuetify | ^2.4.0 | ui-framework | Material Design component library for all UI widgets |
| moment | ^2.29.1 | serialization | Date formatting in account and request list views |
| web-vitals | ^2.1.3 | metrics | CLS, FID, LCP, FCP, TTFB reporting to Google Analytics |
| msw | ^0.35.0 | testing | Mock Service Worker for local API mocking during development |
| core-js | ^3.6.5 | polyfill | Browser polyfills for ES2017+ features |
| jest-axe | ^5.0.1 | testing | Accessibility testing in unit test suite |
| eslint-plugin-vue | ^6.2.2 | linting | Vue-specific ESLint rules |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `package.json` for the full list.
