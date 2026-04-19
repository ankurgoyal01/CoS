---
service: "optimize-suite"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "browser-cookies"
    type: "browser-cookie"
    purpose: "Session and browser identity persistence; cross-page event linkage"
  - id: "session-storage"
    type: "browser-sessionStorage"
    purpose: "Per-session experiment state storage via TrackingHub Warehouse"
---

# Data Stores

## Overview

Optimize Suite is a stateless browser-side library and owns no server-side databases. Its persistence is limited to the browser environment: cookies store identity and cross-page linkage values, and `sessionStorage` (via TrackingHub Warehouse) holds per-session experiment assignments. No migrations, ORMs, or persistent data infrastructure are operated by this service.

## Stores

### Browser Cookies (`browser-cookies`)

| Property | Value |
|----------|-------|
| Type | browser-cookie |
| Architecture ref | `continuumOptimizeSuiteClientBundle` |
| Purpose | Persist session/browser identity and cross-page event linkage |
| Ownership | owned (written by optimize-suite) |
| Migrations path | Not applicable |

#### Key Entities

| Cookie Name | Purpose | Key Fields |
|-------------|---------|-----------|
| `s` | Session identifier; generated client-side if server does not set it | UUID string |
| `b` | Browser identifier; 13-month expiry; falls back to session UUID if missing | UUID string |
| `bh-last-event-id` | Stores the ID of the last Bloodhound click event for cross-page click attribution | Event UUID |
| `bh-last-page-id` | Stores the ID of the last TrackingHub page for cross-page page attribution | Page UUID |
| `scid` | Signed consumer identifier cookie | Hashed ID string |
| `c` | Consumer (user) ID | UUID string |
| `c_s` | Consumer ID source (auth method) | String (`login`, `google_login`, `facebook`, `signup`) |
| `macaroon` | Auth token cookie; parsed to extract `uuid` and `authMethod` | URL-encoded JSON |
| `user_id` | Legacy touch cookie for logged-in detection | String |
| `visited` | Visit tracking cookie | String |
| `_ga` | Google Analytics client cookie; read and forwarded as `dimension11` | GA cookie string |
| `optimize-inspectors` | Dev-mode flag; presence activates `devMode` and inspector overlay | Any value |

#### Access Patterns

- **Read**: On every page load during `init()` — `default-config.js` reads `bh-last-event-id`, `bh-last-page-id`, `c`, `c_s`, `b`, `scid`, `visited`, `user_id`, `macaroon` to build the default config.
- **Write**: `setSessionCookie(id)` writes `s`; `setBrowserCookie(id)` writes `b` with 13-month maxAge; `setLastEventId(id)` writes `bh-last-event-id` on click; `setLastPageId(id)` writes `bh-last-page-id` on TrackingHub page init; `clearLastEventId()` unsets `bh-last-event-id` on each page init.
- **Indexes**: Not applicable (browser cookie store).

### Session Storage / Warehouse (`session-storage`)

| Property | Value |
|----------|-------|
| Type | browser-sessionStorage |
| Architecture ref | `continuumOptimizeSuiteClientBundle` |
| Purpose | Per-session experiment assignment de-duplication via TrackingHub Warehouse |
| Ownership | shared (written by optimize-suite, managed by TrackingHub) |
| Migrations path | Not applicable |

#### Key Entities

| Storage Key | Purpose | Key Fields |
|-------------|---------|-----------|
| `experiments` (via Warehouse `interaction-goals` namespace) | Tracks which experiments have been seen in the current session to prevent duplicate `finch-experiment` events | Array of `{ layer, experiment, variant }` objects |

#### Access Patterns

- **Read**: `TrackingHub.session.get('experiments')` checked on each Finch `run` event to determine if experiment is already tracked.
- **Write**: `TrackingHub.session.set('experiments', [...])` appends new experiment assignments; write failures (storage full) are logged as console warnings in dev mode and silently swallowed in production.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `gaStore` (in-memory) | in-memory JS object | Buffers custom Google Analytics/ClickTale dimension calls that arrive before ClickTale script has loaded | Until `onAdvancedAnalyticsLoaded` fires |

## Data Flows

Cookie data flows into the config object at initialization (`default-config.js`) and is merged with server-provided config (from Optimize I-Tier Bindings) via `deepmerge`. TrackingHub enriches all events with the resulting user/page/session data before flushing to the analytics backend. Cross-page event linkage travels via `bh-last-event-id` and `bh-last-page-id` cookies, which are written on click/page events and read on the next page's `init()` call.
