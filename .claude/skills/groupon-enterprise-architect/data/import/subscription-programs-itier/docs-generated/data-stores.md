---
service: "subscription-programs-itier"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "memcached-membership"
    type: "memcached"
    purpose: "Cache for membership state and feature flag data"
  - id: "in-process-memory"
    type: "in-memory"
    purpose: "Division configs and locale data"
---

# Data Stores

## Overview

subscription-programs-itier uses two tiers of ephemeral caching. Memcached stores serialized membership state and feature flag responses to reduce repeated upstream API calls during an enrollment session. Node.js in-process memory holds division and locale configuration refreshed at startup. The service owns no persistent relational or document database; all durable membership state is owned by the Groupon Subscriptions API.

## Stores

### Memcached (Membership Cache)

| Property | Value |
|----------|-------|
| Type | memcached |
| Architecture ref | `subscriptionProgramsItier` (infrastructure-level; no dedicated container ID in model) |
| Purpose | Cache membership status responses and feature flag evaluations to reduce upstream API load during enrollment sessions |
| Ownership | shared (infrastructure-managed) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Membership status cache entry | Stores current Groupon Select membership state for a user | user ID, membership status, benefits entitlements, TTL |
| Feature flag cache entry | Stores Birdcage feature flag assignments for a session context | session/context key, flag values, TTL |

#### Access Patterns

- **Read**: On page render and `/programs/select/poll` requests, membership status is read from Memcached before calling the Subscriptions API.
- **Write**: Membership status responses from the Subscriptions API are written to Memcached after fetch. Feature flag assignments from Birdcage are cached per session context.
- **Indexes**: Not applicable (Memcached key-value store).

### Node In-Process Memory

| Property | Value |
|----------|-------|
| Type | in-memory |
| Architecture ref | `subscriptionProgramsItier` |
| Purpose | Holds division/locale data loaded at startup by `itier-divisions` |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Division map | Maps division IDs to locale/currency/region config | division ID, locale, currency, region |

#### Access Patterns

- **Read**: Synchronous in-process lookup on every request for locale-dependent rendering; zero network latency.
- **Write**: Loaded at service startup; refreshed on restart or deployment.
- **Indexes**: Not applicable (in-process JavaScript Map/Object).

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Membership status cache | memcached | Caches Groupon Subscriptions API membership state responses | Configured per entry type; no specific value in inventory |
| Feature flag cache | memcached | Caches Birdcage feature flag assignments per session context | Configured per flag |
| Division/locale store | in-memory | Division configs loaded by `itier-divisions` | Until service restart |

## Data Flows

All durable membership state (enrollment records, billing details, benefit entitlements) resides in the Groupon Subscriptions API backend. subscription-programs-itier reads and writes Memcached as a caching layer only. On enrollment (`POST /programs/select/subscribe`), the service calls the Subscriptions API synchronously; the resulting membership state is cached in Memcached. Subsequent `/programs/select/poll` calls read from Memcached first; on a miss or expiry they call the Subscriptions API and update the cache. No data replication or ETL pipeline is involved.
