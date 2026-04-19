---
service: "umapi"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for Universal Merchant API (UMAPI).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Profile Lookup](merchant-profile-lookup.md) | synchronous | API request from upstream consumer | An upstream service or UI requests merchant/place data from UMAPI, which retrieves it and returns the response. |
| [Merchant Onboarding](merchant-onboarding.md) | synchronous | API request from Merchant Center or onboarding service | A new merchant is onboarded through UMAPI, which persists the merchant profile and publishes lifecycle events. |
| [Deal Creation Merchant Sync](deal-creation-merchant-sync.md) | synchronous | API request from Marketing Deal Service | During deal creation, the Marketing Deal Service syncs merchant profile and contact data from UMAPI. |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- **Deal creation flow**: Marketing Deal Service calls UMAPI to sync merchant profile during deal creation (see `dynamic-continuum-runtime` view in central architecture).
- **Merchant page rendering**: Merchant Page Service calls UMAPI to resolve place data by slug.
- **Bookability dashboard login**: Bookability Dashboard uses UMAPI OAuth endpoints for internal user authentication.
- **3PIP onboarding**: 3PIP Merchant Onboarding iTier reads and updates merchant mapping and onboarding state via UMAPI.
