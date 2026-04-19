---
service: "regla"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "reglaPostgresDb"
    type: "postgresql"
    purpose: "Primary relational store for rules, rule instances, actions, executions, users, and purchase records"
  - id: "reglaRedisCache"
    type: "redis"
    purpose: "Low-latency cache for purchase history, rule evaluation state, and taxonomy data"
---

# Data Stores

## Overview

regla uses two data stores: a PostgreSQL database (`reglaPostgresDb`) as the primary store for all durable rule data, and a Redis instance (`reglaRedisCache`) as the high-speed cache for purchase history, rule evaluation state, and taxonomy lookups. Both the `reglaService` and `reglaStreamJob` access both stores.

## Stores

### regla PostgreSQL (`reglaPostgresDb`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `reglaPostgresDb` |
| Purpose | Durable storage for rule definitions, instances, actions, execution history, user data, and purchase records |
| Ownership | owned |
| Migrations path | No evidence found in codebase for migration tool path |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `rules` | Rule definition records including conditions, status, and approval metadata | id, name, conditions, status (draft/approved/active/inactive), created_at, updated_at |
| `rule_instances` | Instances of rules bound to specific events or user segments | id, rule_id, event_type, created_at |
| `rule_actions` | Action definitions triggered when a rule fires (push, email, incentive) | id, rule_id, action_type, action_payload, created_at |
| `executions` | Audit log of rule evaluations and their outcomes | id, rule_id, user_id, triggered_at, outcome, action_dispatched |
| `users` | User records tracked by regla for purchase and browse history | id, user_id, created_at |
| `purchases` | Purchase records used for rule condition evaluation | id, user_id, deal_id, category_id, purchased_at |

#### Access Patterns

- **Read**: Point lookups by user_id and deal_id for evaluation queries (`/userHasDealPurchaseSince`, `/userHasAnyPurchaseEver`); full table scans of active rules for stream job initialisation
- **Write**: Rule CRUD via API; execution records inserted on every rule evaluation; purchase records inserted from stream job
- **Indexes**: No evidence found in codebase for specific index definitions — standard primary key and foreign key indexes assumed; user_id and deal_id indexes expected on `purchases` for evaluation performance

### regla Redis Cache (`reglaRedisCache`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `reglaRedisCache` |
| Purpose | Low-latency cache for purchase history lookups, rule evaluation state, and taxonomy category tree data |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

> No evidence found in codebase for specific Redis key schema definitions.

#### Access Patterns

- **Read**: Purchase history cache lookups keyed by user_id + deal_id during rule evaluation queries and stream processing
- **Write**: Stream job writes updated purchase history and rule state after processing each event
- **Indexes**: Not applicable (Redis key-based access)

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `reglaRedisCache` | redis | Purchase history, rule evaluation state, taxonomy category tree | No evidence found |

## Data Flows

Purchase and browse events consumed by the `reglaStreamJob` result in writes to both Redis (purchase history and rule state cache) and PostgreSQL (execution records, purchase records). Rule definitions are authored and approved via the `reglaService` API and stored in PostgreSQL; the stream job reads active rules from PostgreSQL on startup and refreshes periodically. Taxonomy data is fetched from Taxonomy Service v2 and cached in Redis to reduce repeated lookups during high-throughput stream evaluation.
