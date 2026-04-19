---
service: "android-consumer"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumAndroidLocalStorage"
    type: "sqlite"
    purpose: "Cached API responses, user preferences, session state, sync queue, feature flags"
  - id: "sharedPreferences"
    type: "key-value"
    purpose: "Simple key-value settings and OAuth token storage"
---

# Data Stores

## Overview

The Android Consumer App uses two on-device storage mechanisms: a structured SQLite database accessed via the Room ORM for cached API payloads and offline state, and Android SharedPreferences for simple key-value configuration and token storage. Both stores are local to the device and scoped to the app process. There is no server-side database owned by this service.

## Stores

### Android Local Storage (`continuumAndroidLocalStorage`)

| Property | Value |
|----------|-------|
| Type | sqlite |
| Architecture ref | `continuumAndroidLocalStorage` |
| Purpose | Cached API responses, user preferences, session state, sync queue, feature flags |
| Ownership | owned |
| Migrations path | > No evidence found in codebase. Room migration files expected in module source sets. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Cached deal responses | Store deal listing API payloads for offline browsing | deal ID, payload JSON, TTL timestamp |
| User preferences | Persist app-level user settings | preference key, preference value |
| Session state | Track active user session and auth context | user ID, session token reference, expiry |
| Sync queue | Queue mutations for retry when connectivity is restored | operation type, payload, retry count, timestamp |
| Feature flags | Cache feature flag evaluations from `base-abtests` module | flag name, flag value, fetched-at timestamp |

#### Access Patterns

- **Read**: Feature modules query Room DAOs for cached data before issuing network requests; TTL is checked before serving cached content.
- **Write**: Network Integration Layer writes API response payloads to Room after successful fetch; Local Persistence Layer writes session state on auth events.
- **Indexes**: > No evidence found in codebase. Index definitions are in Room DAO annotations within module source sets.

### SharedPreferences

| Property | Value |
|----------|-------|
| Type | key-value |
| Architecture ref | `continuumAndroidLocalStorage` |
| Purpose | Simple key-value settings and OAuth token storage |
| Ownership | owned |
| Migrations path | > Not applicable — no migrations for SharedPreferences. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| OAuth tokens | Store access and refresh tokens from Okta | access_token, refresh_token, expiry |
| App settings | User-adjustable preferences (notifications, location consent, etc.) | setting key, setting value |

#### Access Patterns

- **Read**: Read on app startup and before authenticated API calls to attach token to requests.
- **Write**: Written on successful OAuth token exchange and user settings changes.
- **Indexes**: Not applicable — key-value store.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Room deal cache | sqlite (in-process) | Cache deal listing API responses for offline browsing | TTL-based, checked at read time |
| Feature flag cache | sqlite (in-process) | Cache A/B test flag evaluations from `base-abtests` | > No evidence found in codebase |

## Data Flows

API responses fetched by `androidConsumer_networkIntegration` are written to `continuumAndroidLocalStorage` via `androidConsumer_localPersistence`. Feature modules read from the local store first; on cache miss or TTL expiry they trigger a network fetch and update the store with the fresh payload. The sync queue in Room buffers mutations (cart, account updates) during connectivity loss and is flushed by WorkManager background jobs when connectivity is restored.
