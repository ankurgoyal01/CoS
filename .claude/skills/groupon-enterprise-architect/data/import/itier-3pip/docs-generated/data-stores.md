---
service: "itier-3pip"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "memcached"
    type: "memcached"
    purpose: "Session and response caching for booking state"
---

# Data Stores

## Overview

itier-3pip does not own a primary persistent data store. All authoritative data — orders, deals, inventory — resides in downstream internal services. The service uses Memcached as a shared cache to hold session state and cache provider API responses, reducing latency and repeated upstream calls during multi-step booking flows.

## Stores

> No persistent database is owned by this service. itier-3pip is largely stateless with respect to durable data.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Session/Response Cache | memcached | Stores user session state and cached provider API responses across booking workflow steps | Not specified in architecture model |

### Cache Detail

- **Technology**: Memcached
- **Purpose**: Maintains booking session continuity across the multi-step iframe flow (availability selection, checkout, confirmation). Also caches provider API responses to reduce redundant outbound calls.
- **Ownership**: Shared infrastructure — the cache is not exclusively owned by itier-3pip.
- **TTL**: Not specified in the architecture model; TTL configuration is expected in Helm values or environment-level config.

## Data Flows

Booking state is written to Memcached at each step of the booking workflow by the `bookingWorkflow` component. The `apiRouter` component reads session data from Memcached on each inbound request to reconstruct context before dispatching to the appropriate workflow handler. No CDC, ETL, or replication patterns are used. Authoritative order and deal data are always fetched from `continuumOrdersService` and `continuumDealCatalogService` respectively.
