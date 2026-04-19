---
service: "clo-service"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumCloServicePostgres"
    type: "postgresql"
    purpose: "Primary relational datastore for CLO domain entities"
  - id: "continuumCloServiceRedis"
    type: "redis"
    purpose: "Queue state, distributed locks, and ephemeral cache"
---

# Data Stores

## Overview

CLO Service owns two data stores: a PostgreSQL database as the primary relational store for all CLO domain entities (enrollments, claims, offers, statement credits), and a Redis instance that serves as the Sidekiq job queue backend, distributed lock store, and ephemeral cache. The `ar-octopus` library provides database sharding support over PostgreSQL. Both stores are accessed exclusively by the CLO Service containers — they are not shared with other services.

## Stores

### CLO Service PostgreSQL (`continuumCloServicePostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumCloServicePostgres` |
| Purpose | Primary relational datastore for CLO domain entities |
| Ownership | owned |
| Migrations path | `db/migrate/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `enrollments` | Records linking a user's payment card to a CLO offer | user id, card network token, offer id, status, enrolled_at |
| `claims` | Records of qualifying purchase transactions matched to enrolled offers | user id, offer id, transaction id, amount, claim status, claimed_at |
| `statement_credits` | Tracks loyalty statement credit fulfillment for approved claims | claim id, user id, amount, credit status, issued_at |
| `offers` | CLO offer definitions ingested from merchants and deal catalog | offer id, merchant id, network, activation status, terms |
| `card_interactions` | Records of card interaction events for tracking and audit | user id, card token, event type, timestamp |
| `users` | CLO-domain user profiles and eligibility state | user id, account status, enrollment eligibility |

#### Access Patterns

- **Read**: Claims and enrollment lookups by user id; offer resolution by merchant or network id; statement credit status queries; admin queries via ActiveAdmin
- **Write**: Claim creation and status transitions (AASM state machine); enrollment create/update/delete; statement credit issuance and status updates; offer upserts during ingestion
- **Indexes**: Indexes on user id, offer id, claim status, and enrolled card tokens are expected given the access patterns; specific index names not evidenced in architecture inventory

### CLO Service Redis (`continuumCloServiceRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumCloServiceRedis` |
| Purpose | Queue state, distributed locks, and ephemeral cache |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Sidekiq queues | Background job queue storage for `continuumCloServiceWorker` | queue name, job payload, retry count |
| Sidekiq locks | Distributed mutex locks preventing duplicate job execution | lock key, TTL |
| Rails cache entries | Ephemeral application cache for frequently read data | cache key, value, TTL |

#### Access Patterns

- **Read**: `continuumCloServiceWorker` polls queues via Sidekiq; cache reads by API layer for frequently accessed offer/user data
- **Write**: `continuumCloServiceApi` enqueues async jobs; workers write job state and locks; Rails cache writes on cache miss
- **Indexes**: Not applicable — Redis key-based access

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumCloServiceRedis` | redis | Rails application cache; Sidekiq job queue and lock store | Varies by cache key; locks are short-lived |

## Data Flows

PostgreSQL is the system of record for all CLO domain state. When an enrollment or claim event occurs, the API layer writes to PostgreSQL and then enqueues an async job via Redis. The worker reads from PostgreSQL to complete processing (e.g., statement credit issuance) and then updates state back in PostgreSQL. Published Message Bus events are derived from PostgreSQL state. Redis does not hold persistent domain state — it is cleared when queues drain and locks expire.
