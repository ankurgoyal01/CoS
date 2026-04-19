---
service: "incentive-service"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumIncentivePostgres"
    type: "postgresql"
    purpose: "Incentive metadata, campaign control tables, approval workflow state"
  - id: "continuumIncentiveCassandra"
    type: "cassandra"
    purpose: "Qualification and redemption datasets (high volume, on-prem)"
  - id: "continuumIncentiveKeyspaces"
    type: "keyspaces"
    purpose: "Cassandra-compatible managed store for cloud environments"
  - id: "continuumIncentiveRedis"
    type: "redis"
    purpose: "Distributed cache refresh, state pub/sub, session-level caching"
  - id: "extBigtableInstance_0f21"
    type: "bigtable"
    purpose: "High-throughput audience and qualification data reads"
---

# Data Stores

## Overview

The Incentive Service uses a multi-store data strategy optimised for each access pattern. PostgreSQL holds authoritative incentive and campaign metadata with relational integrity. Cassandra (and its managed cloud equivalent, Amazon Keyspaces) handles the high-volume qualification and redemption datasets where write throughput and horizontal scalability matter most. Redis provides distributed caching and pub/sub coordination. Google Cloud Bigtable is used for high-throughput reads of audience data in cloud environments (stub integration).

## Stores

### Incentive PostgreSQL (`continuumIncentivePostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumIncentivePostgres` |
| Purpose | Incentive metadata, campaign control tables, approval workflow state |
| Ownership | owned |
| Migrations path | > No evidence found in codebase. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `incentives` | Incentive definitions including type, discount value, and validity window | incentive_id, type, discount_value, valid_from, valid_to |
| `campaigns` | Campaign records including state, quota, and targeting rules | campaign_id, state, quota, audience_rules, targeting |
| `campaign_approval` | Multi-step approval workflow state for campaigns | campaign_id, step, approver, approved_at |
| `quota_counters` | Tracks redemption quota consumed per incentive | incentive_id, redeemed_count, max_quota |

#### Access Patterns

- **Read**: Incentive definition lookup at validation time; campaign detail retrieval in admin UI; quota counter reads during redemption
- **Write**: Incentive and campaign creation and updates via admin API; quota counter increments during redemption; campaign state transitions during approval and expiry
- **Indexes**: > No evidence found in codebase.

---

### Incentive Cassandra (`continuumIncentiveCassandra`)

| Property | Value |
|----------|-------|
| Type | cassandra |
| Architecture ref | `continuumIncentiveCassandra` |
| Purpose | High-volume qualification and redemption records (on-prem environments) |
| Ownership | owned |
| Migrations path | > No evidence found in codebase. |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `redemptions` | Records of promo code redemptions keyed by user and order | user_id, order_id, incentive_id, redeemed_at |
| `qualification_results` | Per-user qualification outcomes for campaign audience sweeps | campaign_id, user_id, qualified, evaluated_at |

#### Access Patterns

- **Read**: Prior redemption check at validation time (by user_id + incentive_id); qualification status queries by campaign
- **Write**: Redemption records written at point of redemption; qualification results written in bulk after audience sweep
- **Indexes**: Partition key design around user_id and campaign_id for efficient lookup patterns

---

### Incentive Keyspaces (`continuumIncentiveKeyspaces`)

| Property | Value |
|----------|-------|
| Type | Amazon Keyspaces (Cassandra-compatible) |
| Architecture ref | `continuumIncentiveKeyspaces` |
| Purpose | Cassandra-compatible managed store for cloud (GCP/AWS) environments |
| Ownership | owned |
| Migrations path | > No evidence found in codebase. |

#### Key Entities

Same schema as `continuumIncentiveCassandra` — `redemptions` and `qualification_results` tables. Keyspaces is used as a drop-in replacement in managed cloud environments where self-hosted Cassandra is not available.

#### Access Patterns

- **Read**: Same as `continuumIncentiveCassandra`
- **Write**: Same as `continuumIncentiveCassandra`
- **Indexes**: Managed by Amazon Keyspaces; partition key design mirrors Cassandra

---

### Incentive Redis (`continuumIncentiveRedis`)

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | `continuumIncentiveRedis` |
| Purpose | Distributed cache refresh, pub/sub state coordination, session-level caching |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Incentive cache entries | Cached incentive definitions to reduce PostgreSQL read load | incentive_id |
| Pub/sub channels | Coordinate state changes across service instances | channel name |

#### Access Patterns

- **Read**: Cache hits for incentive definitions during validation; state reads from pub/sub channels
- **Write**: Cache population after PostgreSQL reads; pub/sub publish on state changes
- **Indexes**: Key-value by incentive_id

---

### Google Cloud Bigtable (`extBigtableInstance_0f21` — stub)

| Property | Value |
|----------|-------|
| Type | Google Cloud Bigtable |
| Architecture ref | `extBigtableInstance_0f21` (stub — not in federated model) |
| Purpose | High-throughput audience and qualification data reads |
| Ownership | external |
| Migrations path | Not applicable |

#### Key Entities

> Not applicable — Bigtable schema is managed externally. The service reads audience membership data from Bigtable as part of audience qualification sweeps.

#### Access Patterns

- **Read**: High-throughput bulk reads of user audience membership during qualification sweeps
- **Write**: Not applicable — Incentive Service is a read-only consumer of Bigtable data
- **Indexes**: Managed by Bigtable row key design; details external to this service

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumIncentiveRedis` | redis | Incentive definition cache; distributed pub/sub state coordination | > No evidence found in codebase. |

## Data Flows

- Incentive definitions are written to PostgreSQL and cached in Redis on first access.
- Redemption records are written to Cassandra (on-prem) or Keyspaces (cloud) at point of redemption.
- Qualification results from audience sweeps are written in bulk to Cassandra or Keyspaces after the Akka job completes.
- Audience membership data is read from Bigtable during qualification sweeps and cross-referenced with user population updates from MBus.
- Quota counters in PostgreSQL are incremented during redemption and checked during validation.
