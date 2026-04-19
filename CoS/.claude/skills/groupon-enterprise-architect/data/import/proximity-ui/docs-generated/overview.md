---
service: "proximity-ui"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Proximity / Location-based Notifications"
platform: "Continuum"
team: "EC Team"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2015+ (Babel-transpiled)"
  framework: "Express / Vue.js"
  framework_version: "Express ^4.13.3 / Vue ^1.0.21"
  runtime: "Node.js"
  runtime_version: "Not pinned in package.json"
  build_tool: "Webpack 1"
  package_manager: "npm"
---

# Proximity UI Overview

## Purpose

Proximity UI is an internal administrator-facing web application that provides a management interface for Groupon's Proximity Notification Service. It enables EC-team administrators to create, browse, and delete proximity hotzones (geofenced push-notification deals) and deal-based campaigns. The application acts as a thin UI layer plus a Node.js/Express proxy that forwards all data operations to the upstream Hotzone API (`continuumProximityHotzoneApi`).

## Scope

### In scope

- Serving the single-page Vue.js admin UI for proximity hotzone management
- Proxying API requests from the browser to `continuumProximityHotzoneApi` under the `/api/proximity/*` path namespace
- User authentication via `X-Remote-User` header inspection (resolved by the upstream reverse proxy / Nginx)
- User-authorization gate: only users in the allowed list from the Hotzone API may access non-permission screens
- Form validation for hotzone and campaign creation inputs (geo-coordinates, deeplinks, image URIs, time ranges)
- Multi-location hotzone bulk creation from a lat/lng/radius text input
- Campaign (deal-based hotzone category configuration) CRUD

### Out of scope

- Hotzone business logic and persistence — owned by `continuumProximityHotzoneApi`
- Push notification delivery — owned by the Proximity Notification Service
- Deal catalog / MDS queries — initiated by the backend campaign processor, not this UI
- Authentication token issuance — delegated to the upstream reverse proxy

## Domain Context

- **Business domain**: Proximity / Location-based Notifications
- **Platform**: Continuum
- **Upstream consumers**: Groupon EC-team administrators via web browser
- **Downstream dependencies**: `continuumProximityHotzoneApi` (HTTP, all data read/write)

## Stakeholders

| Role | Description |
|------|-------------|
| EC Team Administrator | Primary user; creates, reviews, and deletes hotzones and campaigns via the browser UI |
| EC Team Engineer | Owns and operates the service; deploys via Fabric scripts |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (ES2015+, Babel-transpiled) | ES2015 | `package.json` babel-preset-es2015 |
| UI Framework | Vue.js | ^1.0.21 | `package.json` dependencies |
| HTTP Client (browser) | vue-resource | ^0.9.3 | `package.json`, `src/main.js` |
| Server Framework | Express | ^4.13.3 | `package.json` devDependencies |
| Runtime | Node.js | Not pinned | `build/build.js`, `server/` |
| Build tool | Webpack | ^1.13.2 | `package.json`, `build/webpack.*.conf.js` |
| Process manager | forever | 0.15.3 | `package.json` scripts |
| Package manager | npm | — | `package-lock.json`, `.npmrc` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| vue-router | ^0.7.13 | ui-framework | Client-side SPA routing between hotzone management views |
| vue-resource | ^0.9.3 | http-client | AJAX calls from Vue components to the Express proxy API |
| express | ^4.13.3 | http-framework | Server-side request routing and API proxy |
| request | (implicit via `require('request')`) | http-client | Node.js server-side HTTP proxy calls to Hotzone API |
| bootstrap | ^3.3.7 | ui-framework | Responsive layout and base component styling |
| bootstrap-validator | ^0.11.5 | validation | Client-side form validation for hotzone creation inputs |
| bootstrap-select | ^1.11.2 | ui-framework | Enhanced select inputs for deal type and category fields |
| eonasdan-bootstrap-datetimepicker | ^4.17.42 | ui-framework | Date/time picker for hotzone expiry and campaign start fields |
| datatables.net | ^1.10.12 | ui-framework | Server-side paginated table for hotzone browse/summary views |
| bootbox | ^4.4.0 | ui-framework | Confirmation dialogs for bulk create and duplicate-detection warnings |
| lodash | (implicit in controllers) | utility | Used in Express controllers |
| moment-timezone | (implicit via `require('moment-timezone')`) | utility | Timezone-aware date formatting for PT display |
| webpack | ^1.13.2 | build | Bundles Vue SPA assets for production |
| forever | 0.15.3 | scheduling | Keeps Node.js process alive across restarts |
