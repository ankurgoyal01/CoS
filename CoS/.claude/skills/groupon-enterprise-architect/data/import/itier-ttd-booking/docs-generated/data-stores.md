---
service: "itier-ttd-booking"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "memcached-session"
    type: "memcached"
    purpose: "Session caching via itier-client-platform"
---

# Data Stores

## Overview

`itier-ttd-booking` is primarily stateless. It does not own a primary database. The only data store interaction is a shared Memcached instance used for session caching, accessed through the `itier-client-platform` library rather than directly managed by this service.

## Stores

> This service does not own any databases or persistent stores. All deal, user, and reservation data is retrieved on demand from downstream services (`continuumDealCatalogService`, `continuumUsersService`, `continuumGLiveInventoryService`).

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Session cache | memcached | Caches user session data via itier-client-platform | Platform-managed (not configured directly by this service) |

#### Access Patterns

- **Read**: Session lookup on each inbound request via `itier-client-platform` middleware
- **Write**: Session data written by platform middleware on session creation or update
- **Indexes**: Not applicable (key-value store keyed by session token)

## Data Flows

Session data flows through Memcached on every inbound request. Deal, user, and reservation payloads are fetched synchronously from downstream REST services per request and are not cached at this service layer beyond what `itier-client-platform` manages.
