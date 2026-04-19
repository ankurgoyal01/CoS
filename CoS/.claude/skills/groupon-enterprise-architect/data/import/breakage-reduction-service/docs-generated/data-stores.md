---
service: "breakage-reduction-service"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumBreakageReductionRedis"
    type: "redis"
    purpose: "Workflow helper state cache for post-purchase breakage reduction features"
---

# Data Stores

## Overview

BRS owns a single data store: a Redis cache used by the workflow engine and helper logic to maintain per-voucher feature state across requests. BRS has no relational or document database. All persistent voucher, order, deal, and user data is read from external services at request time via the Storage Facade. The service is effectively stateless with respect to business data; Redis is used only for ephemeral workflow coordination state.

## Stores

### Breakage Reduction Redis (`continuumBreakageReductionRedis`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumBreakageReductionRedis` |
| Purpose | Key-value cache for workflow helper state used by notification eligibility and action-scheduling logic |
| Ownership | owned |
| Migrations path | Not applicable — Redis is schema-less |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Workflow helper state keys | Per-voucher or per-user ephemeral state used by the workflow engine to track action scheduling decisions | Bucket, type, key (managed via RISE bucket API) |

#### Access Patterns

- **Read**: Workflow engine reads helper state at the start of a next-actions computation to determine which actions have already been scheduled or are pending
- **Write**: Workflow engine writes updated state after action scheduling decisions are made
- **Indexes**: Not applicable — direct key lookups only

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumBreakageReductionRedis` | Redis | Workflow helper state for post-purchase notification feature logic | Not explicitly documented; managed by the workflow engine |

### Redis Connection Configuration

| Config Key | Staging | Production (US) | Production (EMEA) |
|-----------|---------|-----------------|-------------------|
| `redis.host` | `redis-10130.snc1.raas-shared3-staging.grpn` | `redis-10130.us.raas-shared3-prod.grpn` | `redis-10130.dub1.raas-shared3-prod.grpn` |
| `redis.port` | `10130` | `10130` | `10130` |
| `redis.connect_timeout` | `500` ms | `500` ms | `500` ms |
| `redis.max_attempts` | `10` | `10` | `10` |
| `redis.enable_offline_queue` | `true` | `true` | `true` |

Source: `config/base.cson`

## Data Flows

All business data (vouchers, orders, deals, users, merchants, places, reviews) is fetched on-demand from upstream services at request time via the Storage Facade (`common/Storage.js`). No ETL, CDC, or materialized views are maintained by BRS. Redis state is local to the BRS workflow engine and is not replicated or exported.
