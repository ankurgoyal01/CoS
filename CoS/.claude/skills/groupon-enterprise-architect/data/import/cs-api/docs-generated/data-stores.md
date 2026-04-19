---
service: "cs-api"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "csApiMysql"
    type: "mysql"
    purpose: "Primary read/write store for case memos, snippets, agent roles, and feature flags"
  - id: "csApiRoMysql"
    type: "mysql"
    purpose: "Read-only replica for read-heavy queries"
  - id: "csApiRedis"
    type: "redis"
    purpose: "Dedicated Redis instance for session tokens and response caching"
  - id: "continuumCsRedisCache"
    type: "redis"
    purpose: "Shared Continuum CS Redis cache"
  - id: "csApiRedisC2Cache"
    type: "redis"
    purpose: "Secondary Redis cache layer (C2)"
---

# Data Stores

## Overview

CS API uses two MySQL instances (primary and read replica) for persistent domain data, and three Redis instances for session management and caching. The service owns its MySQL schemas for CS-specific domain objects (memos, snippets, agent roles, features). Redis stores are used to avoid redundant downstream calls and to hold short-lived agent session state.

## Stores

### CS API MySQL Primary (`csApiMysql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `csApiMysql` |
| Purpose | Primary read/write store for memos, snippets, agent roles, and feature flags |
| Ownership | owned |
| Migrations path | > No evidence found in inventory |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `memos` | Case memos written by agents against a customer or order | memo_id, case_id, agent_id, content, created_at |
| `snippets` | Reusable response templates for agent use | snippet_id, title, body, created_by |
| `agent_roles` | Role definitions for CS agents | role_id, role_name, permissions |
| `features` | Feature flag state per agent or context | feature_name, enabled, scope |

#### Access Patterns

- **Read**: Customer/case-scoped memo lookups; role and feature lookups by agent identity
- **Write**: Memo creation and updates; role CRUD; snippet CRUD
- **Indexes**: > No evidence found in inventory

### CS API MySQL Read Replica (`csApiRoMysql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `csApiRoMysql` |
| Purpose | Read-only replica to offload read-heavy queries from the primary |
| Ownership | owned |
| Migrations path | > No evidence found in inventory |

#### Access Patterns

- **Read**: High-frequency read queries (memo lists, snippet lookups) routed via `jtier-daas-mysql` read-replica configuration
- **Write**: Not applicable (read-only)
- **Indexes**: > No evidence found in inventory

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `csApiRedis` | redis | Session token storage and primary response cache | > No evidence found |
| `continuumCsRedisCache` | redis | Shared Continuum CS cross-service cache; CS API writes aggregated results | > No evidence found |
| `csApiRedisC2Cache` | redis | Secondary (C2) cache layer for additional response caching | > No evidence found |

## Data Flows

- Writes to `csApiMysql` (primary) are performed by the `csApi_repositories` component via JDBI.
- Reads for list and lookup operations are routed to `csApiRoMysql` (read replica) via `jtier-daas-mysql` connection pool configuration.
- Session tokens created at `/sessions` are stored in `csApiRedis` and retrieved on subsequent requests by the `authModule` component.
- Aggregated downstream responses (e.g., customer attributes, incentive data) may be written to `continuumCsRedisCache` by the `serviceClients` component to avoid repeat calls within a session.
- `csApiRedisC2Cache` provides a second cache tier for additional hit-rate improvement; the exact eviction policy is not captured in the architecture model.
