---
service: "optimize-suite"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 6
---

# Integrations

## Overview

Optimize Suite integrates with three external analytics/tracking platforms loaded at runtime in the browser, and bundles six internal Groupon Optimize-team libraries as npm dependencies. It is consumed by I-Tier web applications and standalone apps via Layout Service or direct npm inclusion. All external integrations are JavaScript SDK-based (no server-to-server HTTP calls from the library itself).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Analytics (UA / GTM) | SDK (browser JS) | Page view, purchase, subscription event tracking; dimension enrichment | yes | `analyticsPlatforms` |
| ClickTale (Advanced Analytics) | SDK (browser JS) | Session recording and advanced dimension reporting | no | `analyticsPlatforms` |
| Birdcage Experiment Service | Indirect (via server config) | Provides pre-processed experiment configuration consumed by Finch | yes | Not in federated model |

### Google Analytics Detail

- **Protocol**: Browser JavaScript SDK (`analytics.js` loaded from `//www.google-analytics.com/analytics.js`)
- **Base URL / SDK**: `//www.google-analytics.com/analytics.js`; GTM variant uses `gtag`
- **Auth**: Tracking ID configured via `config.googleAnalyticsTrackingId`
- **Purpose**: Sends page views, purchase events (Enhanced Ecommerce), subscription events, and custom dimensions (country, division, channel, app, type, platform, browserId, consumerId, dealUUID, loggedIn, gaCookie) mapped via `gaDimensionMap` to GA dimension slots `dimension1`–`dimension11`
- **Failure mode**: If `googleAnalyticsTrackingId` is not provided, GA initialization is silently skipped. GA load failure does not block tracking.
- **Circuit breaker**: No explicit circuit breaker; GA errors are not surfaced to users.

### ClickTale (Advanced Analytics) Detail

- **Protocol**: Browser JavaScript SDK loaded from `cdnssl.clicktale.net` or `cdn.clicktale.net`
- **Base URL / SDK**: `https://cdnssl.clicktale.net/www29/ptc/9b07ce43-aa6e-4c4f-b93c-fd9e7362bd41.js`
- **Auth**: Hardcoded ClickTale project ID in script URL
- **Purpose**: Session recording and custom dimension reporting; activated via `config.advancedAnalytics.enabled = true`
- **Failure mode**: Silently disabled if `advancedAnalytics.enabled` is false or if ClickTale script fails to load.
- **Circuit breaker**: No; `onAdvancedAnalyticsLoaded` / `ClickTaleOnReady` callback is used for initialization sequencing.

### Birdcage Experiment Service Detail

- **Protocol**: Indirect — Birdcage is fetched and pre-processed server-side by Optimize I-Tier Bindings; the processed config is injected into `window.Optimize.config.finch.config` before optimize-suite is initialized.
- **Base URL / SDK**: `http://birdcage.snc1.` (production snc1), `http://birdcage.dub1.` (production dub1), `http://birdcage-staging.snc1.` (staging) — from `.service.yml`
- **Auth**: Internal service network
- **Purpose**: Provides Finch with experiment layer/variant/bucket configuration; raw Birdcage config cannot be used directly by optimize-suite — pre-processing by Optimize I-Tier Bindings is required.
- **Failure mode**: If no Finch config is provided or `config.finch` is falsy, Finch initialization is skipped.
- **Circuit breaker**: Handled server-side by Optimize I-Tier Bindings.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `tracking-hub` | npm library (in-process) | Manages user/page/session metadata; buffers and flushes tracking payloads to analytics endpoints | Not in federated model (stub: `unknown_trackinghub_8b41967f`) |
| `grpn-finch` | npm library (in-process) | Resolves A/B experiment variants from pre-processed Birdcage config | Not in federated model (stub: `unknown_finchexperimentservice_e9cef36f`) |
| `interaction-goals` | npm library (in-process) | Validates typed interaction message shapes (purchase, subscription); enforces required/optional field contracts | Not in federated model (stub: `unknown_interactiongoals_09c8ea03`) |
| `optimize-error-catcher` | npm library (in-process) | Captures uncaught browser errors and forwards as `uncaught-error` TrackingHub events | Not in federated model (stub: `unknown_optimizeerrorcatcher_8b3ab98e`) |
| `optimize-portal` | npm library (in-process) | Coordinates cross-window (iframe) Optimize communication for TrackingHub, Finch, and SanityCheck channels | Not in federated model (stub: `unknown_optimizeportal_9cb43f75`) |
| `@grpn/domain-cookie` | npm library (in-process) | BAST-compliant cross-subdomain cookie read/write; provides `window.Cookie` global | Internal Groupon library |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Layout Service | npm package inclusion | Bundles `optimize-suite.js` into the I-Tier layout script delivered to every Groupon page |
| Non-I-Tier / Standalone Apps | npm package inclusion (`optimize-suite-standalone.js`) | Direct npm install; includes polyfills for environments without Layout Service |
| MBNXT (Next.js PWA) | npm package inclusion | Integrates tracking and experimentation in the Next.js frontend; passes `session.referrer` override for SPA navigation |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

TrackingHub flush failures are emitted as `error` events on the TrackingHub internal bus. If `config.suppressErrors` is true (default in production), these errors are swallowed. In `devMode`, errors are re-thrown. No explicit retry policy or circuit breaker is implemented at the optimize-suite layer — retry logic is owned by TrackingHub's Beagle buffer, which persists unsent messages across page transitions.
