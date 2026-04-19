---
service: "arbitration-service"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "absPostgres"
    type: "postgresql"
    purpose: "Campaign metadata, delivery rules, user attributes, eligibility records"
  - id: "absCassandra"
    type: "cassandra"
    purpose: "Send history, frequency caps, high-volume operational records"
  - id: "absRedis"
    type: "redis"
    purpose: "Decisioning counters, cached campaign data, TTL-based rate limit keys"
---

# Data Stores

## Overview

The Arbitration Service uses three data stores with distinct roles: PostgreSQL stores durable campaign configuration and rule data, Cassandra stores high-volume send history and cap records optimized for time-series writes, and Redis provides low-latency counters and cache on the hot decisioning path.

## Stores

### PostgreSQL (`absPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `absPostgres` |
| Purpose | Campaign metadata, delivery rules, user attributes, eligibility records |
| Ownership | owned |
| Migrations path | > No evidence found in codebase |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| delivery_rules | Stores delivery rule definitions governing arbitration behavior | id, rule type, conditions, status |
| campaign_metadata | Campaign definitions and attributes used during eligibility evaluation | campaign_id, channel, attributes |
| user_attributes | User-level targeting and eligibility attributes | user_id, attribute key/value pairs |

#### Access Patterns

- **Read**: Queried during best-for selection to evaluate eligibility rules and user attributes; also read on startup for cache preloading
- **Write**: Updated during delivery rule CRUD operations (create, update, delete via admin API)
- **Indexes**: > No evidence found in codebase for specific index definitions

### Apache Cassandra (`absCassandra`)

| Property | Value |
|----------|-------|
| Type | cassandra |
| Architecture ref | `absCassandra` |
| Purpose | Send history, frequency caps, high-volume operational records |
| Ownership | owned |
| Migrations path | > No evidence found in codebase |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| send_history | Records of previously sent campaigns per user | user_id, campaign_id, sent_at |
| frequency_caps | Per-user frequency cap tracking records | user_id, cap_key, count, window |

#### Access Patterns

- **Read**: Queried during best-for selection to check send history and frequency cap state for each candidate campaign
- **Write**: Written during arbitration (persisting the winning send record) and during revoke (marking a send as revoked)
- **Indexes**: Partition keys are expected to be user-centric for efficient per-user lookups; specific schema not available in inventory

### Redis (`absRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `absRedis` |
| Purpose | Decisioning counters, cached campaign data, TTL-based rate limit keys |
| Ownership | owned |
| Migrations path | > Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Rate limit keys | TTL-based keys enforcing frequency limits on the hot path | user_id + cap_type + window |
| Campaign cache | Cached campaign data for low-latency reads | campaign_id |
| Decisioning counters | Real-time counters used during arbitration scoring | counter key, value |

#### Access Patterns

- **Read**: Queried on every decisioning request for real-time counter state and cached campaign data
- **Write**: Incremented/updated during arbitration; decremented during revoke
- **Indexes**: > Not applicable — Redis key-value access by key pattern

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `absRedis` | redis | Decisioning counters, campaign data cache, TTL rate limit keys | TTL-based per key type |
| In-memory delivery rule cache | in-memory | Preloaded delivery rules from PostgreSQL to avoid per-request DB reads | Refreshed on startup and rule updates |
| In-memory experiment config cache | in-memory | Optimizely experiment definitions preloaded at startup and refreshed periodically | Refreshed via `/experiment-config/refresh` |

## Data Flows

On service startup, delivery rules are preloaded from `absPostgres` and experiment config is fetched from `optimizelyService` into in-memory caches. During a best-for request, `absPostgres` is queried for eligibility rules, `absCassandra` is queried for send history and frequency caps, and `absRedis` is queried for real-time counters — all reads are combined to produce the eligible campaign ranking. During arbitration, the winner send record is persisted to `absCassandra` and counters in `absRedis` are incremented. During revoke, the send record in `absCassandra` is marked revoked and `absRedis` counters are adjusted accordingly.
