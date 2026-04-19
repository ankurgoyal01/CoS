---
service: "checkout-reloaded"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumCheckoutReloadedDb"
    type: "postgresql"
    purpose: "Persists checkout session and order state on behalf of the BFF"
---

# Data Stores

## Overview

checkout-reloaded is a stateless BFF and does not own or directly manage any data stores as a primary concern. The single associated PostgreSQL instance (`continuumCheckoutReloadedDb`) is accessed via the `checkoutReloaded_repository` component to persist and retrieve checkout session state during the lifecycle of a checkout request. All authoritative order and payment data lives in downstream service databases.

## Stores

### Checkout Reloaded Database (`continuumCheckoutReloadedDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumCheckoutReloadedDb` |
| Purpose | Persists and loads checkout sessions and in-progress order state for the BFF layer |
| Ownership | owned |
| Migrations path | > No evidence found in codebase. |

#### Key Entities

> No evidence found in codebase. Schema details are not available from the service inventory. The store is accessed via the `checkoutReloaded_repository` component and is expected to hold checkout session records keyed by session or order identifier.

#### Access Patterns

- **Read**: Checkout Repository loads an existing session record at the start of a checkout or receipt page render to restore in-progress state
- **Write**: Checkout Repository writes or updates session state during checkout submission and order confirmation steps
- **Indexes**: > No evidence found in codebase.

## Caches

> No evidence found in codebase. No dedicated cache layer (Redis, Memcached, or in-memory) is documented for this service.

## Data Flows

Checkout session data originates from the consumer's browser interaction. The BFF writes intermediate checkout state to `continuumCheckoutReloadedDb` via `checkoutReloaded_repository`. Upon successful order finalization, authoritative order data is owned by the Order Service's database; the BFF reads back order details from the Order Service API to render the receipt page.
