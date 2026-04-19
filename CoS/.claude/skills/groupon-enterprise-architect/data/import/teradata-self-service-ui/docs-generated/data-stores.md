---
service: "teradata-self-service-ui"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

The Teradata Self Service UI is a stateless frontend application. It owns no persistent data stores. All account, request, and user data is fetched from and written to the `teradata-self-service-api` backend service on each page load or user action. The only client-side state is held transiently in the Vuex store in browser memory and is discarded on page navigation or reload.

## Stores

> This service is stateless and does not own any data stores.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Vuex store | in-memory | Holds the current session's accounts, requests, history, user profile, and configuration for the duration of the browser session | Session lifetime (cleared on reload) |
| Nginx static asset cache | browser cache | Static assets (JS, CSS, PNG, SVG, ICO) served with `Cache-Control: public, max-age=31536000, immutable` | 1 year (immutable fingerprinted assets) |
| Nginx HTML cache | browser cache | `index.html` served with `Cache-Control: no-cache` to force revalidation on every request | No cache (revalidated) |

## Data Flows

Reads: On application load, the SPA dispatches Vuex actions that call `GET /api/v1/users/:userName`, `GET /api/v1/configuration`, `GET /api/v1/accounts`, and `GET /api/v1/requests` in sequence. The responses are stored in the Vuex store and drive all rendered views.

Writes: User-initiated mutations (new account, password reset, approval) call the appropriate `PUT`/`POST` backend endpoints. On success the store is partially updated (e.g., the new request is prepended to history via `addHistory`), and a full account refresh is triggered to reflect the backend state.
