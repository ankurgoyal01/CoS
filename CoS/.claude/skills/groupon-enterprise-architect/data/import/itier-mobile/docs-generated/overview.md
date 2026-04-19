---
service: "itier-mobile"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Mobile App Acquisition & Deep-Link Routing"
platform: "Continuum"
team: "InteractionTier"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2021 (Node.js ^16)"
  framework: "itier-server"
  framework_version: "^7.14.0"
  runtime: "Node.js"
  runtime_version: "^16"
  build_tool: "webpack ^5.46.0"
  package_manager: "npm"
---

# I-Tier Mobile Redirect Overview

## Purpose

`itier-mobile` is the Groupon I-Tier service responsible for directing web users toward Groupon's native mobile apps. It resolves deep-link dispatch requests for iOS and Android devices, serves the `/mobile` download landing page with SMS link delivery, manages Apple Universal Links and Android App Links association files, and provides iPad-specific intercept pages. The service operates globally across US, EMEA, and APAC markets.

## Scope

### In scope

- Serving the `/mobile` landing page and redirecting users to platform-appropriate app store download links
- Dispatching `/dispatch/{country}/*` routes to native app deep-links (deal, channel, search, voucher, Buy With Friends, webview, business)
- Sending SMS messages containing app download links via the Twilio API (`POST /mobile/send_sms_message`)
- Serving Apple App Site Association files (`/apple-app-site-association`) and Android asset links (`/.well-known/assetlinks.json`) for Universal Links / App Links
- Rendering iPad intercept pages (`/mobile/ipad`, `/mobile/ipad_email_to_app`)
- Serving the mobile download redirect (`/mobile/download`) and deep-link launcher (`/mobile/link`)
- Serving the `/subscription` page experience
- Delivering localization translation assets (`/v1/trees/-/{packageId}`, `/v2/translations/{packageId}`)
- Supporting campaign tracking via `grpn_dl` query parameter and Kochava links

### Out of scope

- Native iOS or Android app code
- Primary Groupon web frontend rendering (handled by `citydeal_app` / MBNXT / legacyWeb)
- Routing configuration (managed by the GROUT team's routing-service)
- App store submissions or app release management

## Domain Context

- **Business domain**: Mobile App Acquisition & Deep-Link Routing
- **Platform**: Continuum (I-Tier application layer)
- **Upstream consumers**: Web browsers (desktop and mobile), native Groupon iOS/Android apps, Akamai CDN, Hybrid Boundary ingress layer, routing-service
- **Downstream dependencies**: Twilio (SMS delivery), layout-service (page scaffolding), conveyor-cloud (hosting), Kochava (iOS attribution tracking)

## Stakeholders

| Role | Description |
|------|-------------|
| Owner | schaurasia (InteractionTier) |
| Team | InteractionTier — i-tier-devs@groupon.com |
| On-call | i-tier-mobile-redirect-page@groupon.pagerduty.com |
| PagerDuty | https://groupon.pagerduty.com/services/PY7QIOI |
| Slack | #itier-spam (channel ID: CEKPZDR25) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (Node.js) | ^16 | `package.json` engines, `Dockerfile` |
| Framework | itier-server | ^7.14.0 | `package.json` dependencies |
| Runtime | Node.js / alpine-node16 | 16.16.0 | `Dockerfile` base image |
| Build tool | webpack | ^5.46.0 | `package.json` devDependencies |
| Asset uploader | napistrano (nap) | ^2.184.0 | `package.json` devDependencies |
| Package manager | npm | — | `.npmrc`, `package.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `itier-server` | ^7.14.0 | http-framework | Core I-Tier Node.js HTTP server and routing |
| `keldor` | ^7.3.9 | http-framework | Configuration and service middleware |
| `twilio` | ^3.59.0 | messaging | Sends SMS messages with app download links |
| `gofer` | ^5.2.0 | http-client | Service-to-service HTTP client |
| `@grpn/graphql` | ^4.0.0 | http-client | GraphQL client wrapper |
| `@grpn/graphql-gapi` | ^6.0.0 | http-client | Groupon API GraphQL gateway client |
| `itier-feature-flags` | ^3.2.0 | feature-flags | Runtime feature flag evaluation |
| `preact` | ^10.5.13 | ui-framework | Lightweight React-compatible UI rendering |
| `remote-layout` | ^10.12.1 | ui-framework | Remote layout composition for I-Tier pages |
| `ua-parser-js` | ^0.7.28 | detection | User-agent parsing for iOS/Android/iPad detection |
| `itier-instrumentation` | ^9.13.4 | metrics | Telemetry and application instrumentation |
| `itier-tracing` | ^1.6.1 | metrics | Distributed tracing integration |
| `itier-localization` | ^11.0.3 | serialization | Locale and translation management |
| `itier-routing` | ^5.1.7 | http-framework | I-Tier route registration |
| `lodash` | ^4.17.21 | utility | General-purpose utility functions |
