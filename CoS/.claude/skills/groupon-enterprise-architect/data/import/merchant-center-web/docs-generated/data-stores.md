---
service: "merchant-center-web"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "browser-storage"
    type: "browser"
    purpose: "Session and local state persistence in the user's browser"
---

# Data Stores

## Overview

Merchant Center Web does not own or operate any server-side data stores. All persistent merchant data is stored and managed by the upstream UMAPI and AIDG backend services. The application uses browser-native storage mechanisms only for transient client-side state (authentication tokens, user preferences, cached API responses managed by @tanstack/react-query).

## Stores

### Browser Session / Local Storage (`browser-storage`)

| Property | Value |
|----------|-------|
| Type | browser (sessionStorage / localStorage) |
| Architecture ref | `merchantCenterWebSPA` |
| Purpose | Stores transient client state: auth tokens, user preferences, react-query cache |
| Ownership | owned (client-side, per-user-session) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Auth session token | Maintains authenticated Doorman SSO session across page loads | session token, expiry |
| React Query cache | In-memory cache of API responses to reduce redundant network calls | query key, data, staleness |

#### Access Patterns

- **Read**: SPA reads session tokens on route transitions to enforce authentication guards; reads react-query cache before issuing network requests.
- **Write**: Written on successful SSO login; react-query writes on successful API responses.
- **Indexes**: Not applicable — browser key-value store.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| React Query in-memory cache | in-memory | Avoids redundant API calls within a browser session | Configurable per-query (staleTime / gcTime) |

## Data Flows

All persistent data flows through the browser to UMAPI and AIDG via HTTPS. No ETL, CDC, or replication patterns exist at this layer. The SPA is stateless from the server's perspective.

> This service is stateless server-side and does not own any server-side data stores.
