---
service: "itier-merchant-inbound-acquisition"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchant Experience — Acquisition"
platform: "Continuum (itier)"
team: "Metro Dev BLR"
status: active
tech_stack:
  language: "TypeScript / JavaScript"
  language_version: "TypeScript ~3.8.0 / ES2019"
  framework: "itier-server"
  framework_version: "7.7.2"
  runtime: "Node.js"
  runtime_version: "^14.19.3"
  build_tool: "webpack"
  package_manager: "npm >=6.0.0"
---

# Merchant Inbound Acquisition Overview

## Purpose

Merchant Inbound Acquisition (MIA, also known as Web2Lead / W2L) is Groupon's public-facing web application that allows prospective merchants to register their business with Groupon. It collects merchant contact, location, and business-category data through multi-step signup forms, validates and deduplicates leads, then routes them to either the Metro draft merchant service or Salesforce CRM depending on the merchant's country and feature-flag configuration.

## Scope

### In scope

- Serving the `/merchant/signup` and `/merchant/signup/marketing` family of HTML pages across all supported locales
- Exposing BFF API endpoints for geo-autocomplete, place-details lookup, lead creation, field validation (dedupe), and client configuration loading
- Integrating with the Metro draft service (`@grpn/metro-client`) to create draft merchant records
- Integrating with Salesforce (`jsforce`) to create CRM lead objects for selected lead flows
- Country- and region-scoped feature flag evaluation (via `keldor` / `itier-feature-flags`) to enable/disable form fields, lead routing, and incentive flows
- Client-side React/Preact single-page form with Redux state management and GTM/GA analytics instrumentation
- Localization of form labels and copy via `@grpn/l10n-itier-merchant-inbound-acquisition` and `itier-localization`

### Out of scope

- Processing or underwriting merchant applications (owned by downstream Metro / MerchantCenter systems)
- Merchant account creation and authentication post-submission (handled by Draft Service / Merchant Center)
- CRM pipeline management (Salesforce owns post-lead lifecycle)
- Consumer-facing deal or coupon functionality

## Domain Context

- **Business domain**: Merchant Experience — Acquisition
- **Platform**: Continuum (interaction-tier / itier)
- **Upstream consumers**: Prospective merchants via browser; marketing landing pages linking to `/merchant/signup`
- **Downstream dependencies**: Metro draft service, Salesforce CRM, Groupon V2 address-autocomplete API (`continuumApiLazloService`), Google Analytics, Google Tag Manager

## Stakeholders

| Role | Description |
|------|-------------|
| Team owner | Metro Dev BLR — metro-dev-blr@groupon.com |
| On-call / SRE | metro-ui@groupon.pagerduty.com — PagerDuty service PVDWNAE |
| Product | Metro / Merchant Experience product org |
| Jira project | MIA (https://jira.groupondev.com — rapidView 2597) |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | ~3.8.0 | `package.json` |
| Language | JavaScript (Node) | ES2019 | `package.json` |
| Framework | itier-server | 7.7.2 | `package.json` |
| UI rendering | React | ^16.13.1 | `package.json` |
| UI rendering (SSR) | Preact | ^10.5.13 | `package.json` |
| Runtime | Node.js | ^14.19.3 | `package.json` engines |
| Build tool | webpack | ^4.41.2 | `package.json` |
| Package manager | npm | >=6.0.0 | `package.json` engines |
| Container base | alpine-node16.15.0 | 2022.05.23 | `Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `itier-server` | ^7.7.2 | http-framework | Core itier HTTP server and routing |
| `keldor` | ^7.3.7 | http-framework | Keldor application framework / middleware |
| `keldor-config` | ^4.19.0 | http-framework | CSON-based hierarchical configuration loader |
| `@grpn/metro-client` | ^1.2.0 | http-client | Client for Metro draft merchant and PDS APIs |
| `jsforce` | ^1.8.4 | http-client | Salesforce REST API client for lead creation |
| `itier-feature-flags` | ^1.5.0 | feature-flags | Country/region-scoped feature flag evaluation |
| `itier-localization` | ^10.3.0 | i18n | Locale and translation support |
| `react-redux` | ^7.1.3 | state-management | Redux bindings for React signup form |
| `redux-form` | ^8.2.6 | state-management | Form state management in Redux |
| `itier-tracing` | ^1.6.1 | logging | Structured request tracing / steno logging |
| `itier-instrumentation` | ^9.10.4 | metrics | Application-level metrics and instrumentation |
| `universal-analytics` | ^0.4.17 | metrics | Server-side Google Analytics event tracking |
| `libphonenumber-js` | ^1.11.14 | validation | International phone number validation |
| `itier-groupon-v2-client` | ^4.1.7 | http-client | Groupon V2 API client (address autocomplete) |
