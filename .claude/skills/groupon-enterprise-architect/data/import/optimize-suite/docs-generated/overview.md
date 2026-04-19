---
service: "optimize-suite"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Optimize — User Tracking & Experimentation"
platform: "Continuum (I-Tier / Browser)"
team: "Optimize"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "ES2015+"
  framework: "Webpack"
  framework_version: "5.39.1"
  runtime: "Node.js"
  runtime_version: ">=12.17"
  build_tool: "@grpn/itier-webpack 12.1.0"
  package_manager: "npm"
---

# Optimize Suite Overview

## Purpose

Optimize Suite is a browser-side JavaScript client library that bundles Groupon's user tracking, A/B experimentation, and analytics capabilities into a single distributable artifact. It is distributed via Groupon's internal npm registry and delivered to I-Tier applications through the Layout Service, making its functionality available on every instrumented Groupon page. The library wires together several loosely coupled Optimize-team libraries — Bloodhound, TrackingHub, Finch, InteractionGoals, and ErrorCatcher — into a unified initialization lifecycle accessible via `window.OptimizeSuite`.

## Scope

### In scope
- DOM element impression tracking (Bloodhound engine — `data-bhw`, `data-bhc` attributes)
- Click and interaction event capture and forwarding to TrackingHub
- A/B experiment variant resolution and tracking via Finch
- Session and browser identity cookie management (`s`, `b`, `scid`, `bh-last-event-id`, `bh-last-page-id`)
- Google Analytics (UA and GA4/GTM) integration and dimension mapping
- ClickTale/advanced analytics integration
- Uncaught client-side error capture and reporting
- Referral attribution (UTM parameters, direct, email)
- SPA page-transition support via `treatAsNewPage`
- Cross-window (iframe) tracking coordination via Optimize Portal

### Out of scope
- Server-side experiment configuration (handled by Birdcage experiment service)
- Pre-processing of Birdcage config before delivery to the client (handled by Optimize I-Tier Bindings)
- Hosting and bundling into pages (handled by Layout Service)
- Backend tracking pipeline ingestion (handled by downstream analytics platforms)

## Domain Context

- **Business domain**: Optimize — User Tracking & Experimentation
- **Platform**: Continuum (I-Tier / Browser)
- **Upstream consumers**: I-Tier web applications (via Layout Service), standalone non-I-Tier apps (via `optimize-suite-standalone.js`), MBNXT Next.js PWA
- **Downstream dependencies**: TrackingHub (event buffering/dispatch), Finch experiment service (variant resolution), Birdcage (experiment config, fetched server-side by Optimize I-Tier Bindings), Google Analytics, ClickTale, Optimize Portal (cross-window messaging)

## Stakeholders

| Role | Description |
|------|-------------|
| Optimize Team (optimize@groupon.com) | Owns and maintains this library; handles releases via `nlm` |
| I-Tier / Frontend Teams | Consume optimize-suite through Layout Service; instrument pages with `data-bhw`/`data-bhc` attributes |
| SRE / Monitoring | Monitor via Wavefront dashboards and PagerDuty (P0Q2SV8) |
| Analytics / Data Engineering | Consume tracking events forwarded by TrackingHub to analytics platforms |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | ES2015+ | `package.json`, `lib/` source |
| Build tool | Webpack | 5.39.1 | `package.json` devDependencies |
| Build config | @grpn/itier-webpack | 12.1.0 | `webpack.config.js` |
| Runtime | Node.js | >=12.17 | `package.json` engines field |
| Package manager | npm | — | `.npmrc`, `package-lock.json` |
| Test runner | Mocha | 9.0.1 | `package.json` devDependencies |
| Coverage | c8 | 7.7.3 | `package.json` c8 config |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `tracking-hub` | ^1.20.0 | message-client | Manages user/page/session metadata and buffers tracking payloads; dispatches to analytics endpoints |
| `grpn-finch` | ^1.17.6 | experimentation | Resolves A/B experiment variants; fires experiment tracking events |
| `interaction-goals` | ^2.0.0 | validation | Enforces typed interaction message formats (purchase, subscription, etc.) |
| `optimize-error-catcher` | ^1.3.2 | logging | Captures uncaught browser errors and forwards as `uncaught-error` events |
| `optimize-portal` | ^2.0.0 | messaging | Coordinates cross-window (iframe) Optimize communication |
| `optimize-evented` | ^2.0.0 | state-management | Lightweight event emitter used by Bloodhound and suite components |
| `@grpn/domain-cookie` | ^2.22.0 | auth | Cross-subdomain cookie read/write (BAST-compliant) |
| `@grpn/optimize-inspectors` | ^1.0.6 | tooling | Dev-mode inspector overlay for Bloodhound widget debugging |
| `deepmerge` | ^4.2.2 | serialization | Deep-merges runtime config objects |
| `lodash.debounce` | ^4.0.8 | scheduling | Debounces `treatAsNewPage` scan calls |
| `sanity-check` | ^1.1.1 | validation | Runtime invariant checks with Portal reporting |
| `core-js` | ^2.6.11 | polyfill | ES5/ES6 polyfills for IE11/Safari 11 compatibility |
| `whatwg-fetch` | ^3.5.0 | http-framework | `fetch` polyfill for legacy browsers |
| `promise-polyfill` | ^8.2.0 | polyfill | `Promise` polyfill for legacy browsers |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
