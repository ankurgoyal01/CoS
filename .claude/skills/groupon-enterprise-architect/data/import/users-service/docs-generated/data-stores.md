---
service: "users-service"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumUsersDb"
    type: "mysql"
    purpose: "Primary relational store for accounts, authentication events, and audit data"
  - id: "continuumUsersRedis"
    type: "redis"
    purpose: "Resque queue backing store, cache, and lightweight feature flags"
---

# Data Stores

## Overview

Users Service owns two data stores: a MySQL database (`continuumUsersDb`) as the primary relational store for all user account state, and a Redis instance (`continuumUsersRedis`) serving as the Resque job queue, application cache, and lightweight feature flag store. All three runtime processes — the API, Resque workers, and Message Bus Consumer — access both stores via ActiveRecord and the Redis client respectively.

## Stores

### Users DB (`continuumUsersDb`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `continuumUsersDb` |
| Purpose | Primary relational store for accounts, authentication events, and audit data |
| Ownership | owned |
| Migrations path | `db/migrate/` (within users-service repository) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `accounts` | Core user account records | id, email, status, locale, created_at, updated_at |
| `passwords` | Hashed credential storage | account_id, password_digest (bcrypt), created_at |
| `authentication_events` | Audit log of authentication attempts and outcomes | account_id, strategy, device_fingerprint, success, created_at |
| `tokens` | Session, continuation, and 2FA enforcement tokens | account_id, token_type, value, expires_at |
| `message_bus_messages` | Outbox records for async event publishing | id, topic, payload, status (pending/published/eaten), created_at |
| `third_party_links` | External identity associations (Google, Facebook, Apple) | account_id, provider, external_id, created_at |
| `email_verifications` | Nonce-based email verification state | account_id, nonce, expires_at, completed_at |
| `password_resets` | Self-service and forced password reset tokens | account_id, token, expires_at, completed_at |

#### Access Patterns

- **Read**: Account lookup by email/ID for authentication; authentication event queries for device detection; pending `message_bus_messages` by the Resque worker; account queries in the Message Bus Consumer for forced reset processing
- **Write**: Account creation and updates via Account Strategies; authentication event recording per login attempt; outbox inserts for every published event; token persistence by Token Service; third-party link creation and deletion
- **Indexes**: Account lookup by email (unique), token lookup by value, message_bus_messages by status for worker polling

### Users Redis (`continuumUsersRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumUsersRedis` |
| Purpose | Resque queue backing store, application cache, and lightweight feature flags |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Resque queues | Background job queues for all worker job types | queue name, job payload |
| Cache entries | Short-lived cached responses and account lookups | cache key, serialized value, TTL |
| Feature flags | Lightweight boolean flags used across controllers and strategies | flag name, boolean value |
| Consumer coordination state | Transient retry and consumer coordination state for Message Bus Consumer | consumer key, retry count |

#### Access Patterns

- **Read**: Resque workers poll queues; Cache Client reads cached account/flag state before hitting MySQL
- **Write**: API enqueues Resque jobs; Cache Client writes cached values on cache miss; Message Bus Consumer writes retry state

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumUsersRedis` | redis | Application cache for account lookups and feature flags | Per-key; not discoverable from inventory |

## Data Flows

1. HTTP request arrives at `continuumUsersService`; Account Repository writes to `continuumUsersDb` and Cache Client reads/writes `continuumUsersRedis`.
2. Account & Auth Event Publishers insert a `message_bus_messages` record in `continuumUsersDb` and enqueue a Resque job to `continuumUsersRedis`.
3. Resque workers consume from `continuumUsersRedis`, read the `message_bus_messages` record from `continuumUsersDb`, publish to `continuumUsersMessageBusBroker`, and update the record status.
4. Message Bus Consumer reads from `continuumUsersMessageBusBroker`, updates `continuumUsersDb` records via ActiveRecord, and writes transient state to `continuumUsersRedis`.
