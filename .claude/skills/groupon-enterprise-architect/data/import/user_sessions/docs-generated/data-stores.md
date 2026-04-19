---
service: "user_sessions"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "memcachedCluster_6e2f"
    type: "memcached"
    purpose: "Session and authentication data caching"
---

# Data Stores

## Overview

user_sessions does not own a persistent database. Its only data storage is a shared Memcached cluster used to cache authenticated session objects. All durable user data (credentials, account records, password reset tokens) is owned and persisted by GAPI and the upstream user services it fronts. This service is effectively stateless beyond the session cache.

## Stores

> No evidence found in codebase for a primary relational or document database owned by this service.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `memcachedCluster_6e2f` | memcached | Stores authenticated user session data after successful login, social OAuth, or registration | No evidence found — TTL expected to be configured via `SESSION_SECRET` / session middleware settings |

### Memcached Session Cache (`memcachedCluster_6e2f`)

| Property | Value |
|----------|-------|
| Type | memcached |
| Architecture ref | `memcachedCluster_6e2f` |
| Purpose | Session and authentication data caching |
| Ownership | shared |
| Migrations path | Not applicable — schema-less cache |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Session object | Holds authenticated user identity and session metadata after login | user ID, session token, expiry |

#### Access Patterns

- **Read**: Session lookup on each authenticated request to validate the session cookie
- **Write**: Session creation immediately after successful login, social OAuth token exchange, or new account registration
- **Indexes**: Not applicable — keyed by session token derived from cookie

## Data Flows

After a user successfully authenticates (email/password, Google OAuth, Facebook OAuth, or registration), `authFlows` calls `cacheAdapter`, which writes the session object to Memcached via `itier-cached`. On subsequent requests, the session is retrieved from Memcached using the cookie value as the lookup key. No replication, ETL, or CDC processes are used — this is a volatile cache; session loss on Memcached restart requires the user to re-authenticate.
