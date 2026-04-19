---
service: "itier-3pip-merchant-onboarding"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "in-memory-session-cache"
    type: "in-memory"
    purpose: "Short-lived session and response caching via itier-cached"
---

# Data Stores

## Overview

This service is stateless and does not own any persistent data stores. All merchant onboarding and identity state is delegated to downstream services (`continuumUniversalMerchantApi`, `continuumPartnerService`, `continuumUsersService`). The only local storage is an in-memory session cache provided by `itier-cached` for short-lived response caching within a single process instance.

## Stores

> This service is stateless and does not own any data stores.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `itier-cached` session cache | in-memory | Caches transient session and API response data within the Node.js process | Process-lifetime / request-scoped |

## Data Flows

All persistent merchant data originates from and is written back to:
- `continuumUniversalMerchantApi` — merchant 3PIP mapping and auth state
- `continuumPartnerService` — partner onboarding and auth records
- `continuumUsersService` — merchant user profile data
- `salesForce` — CRM onboarding state (synchronized outbound only)

No ETL, CDC, or replication patterns exist within this service.
