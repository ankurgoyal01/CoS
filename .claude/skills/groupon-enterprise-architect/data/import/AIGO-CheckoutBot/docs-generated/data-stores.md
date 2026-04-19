---
service: "AIGO-CheckoutBot"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "continuumAigoPostgresDb"
    type: "postgresql"
    purpose: "Primary relational datastore for all application domains"
  - id: "continuumAigoRedisCache"
    type: "redis"
    purpose: "Transient state, SSE token storage, and distributed coordination"
---

# Data Stores

## Overview

AIGO-CheckoutBot owns two data stores. PostgreSQL (`continuumAigoPostgresDb`) is the primary durable store, organized into four schemas covering conversation design, runtime engine state, analytics, and simulation. Redis (`continuumAigoRedisCache`) provides fast transient storage for SSE delivery tokens, event recovery buffers, and distributed locks. The `backendDataAccess` component within `continuumAigoCheckoutBackend` mediates all access to both stores via typed repository classes.

## Stores

### AIGO PostgreSQL (`continuumAigoPostgresDb`)

| Property | Value |
|----------|-------|
| Type | PostgreSQL |
| Architecture ref | `continuumAigoPostgresDb` |
| Purpose | Primary relational datastore for design, engine, analytics, and simulation schemas |
| Ownership | owned |
| Migrations path | Managed by `node-pg-migrate` 7.9.1 |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `ng_design.*` (schema) | Stores decision tree nodes, prompts, actions, conditions, and project configuration | project_id, node_id, prompt_content, condition_rules |
| `ng_engine.*` (schema) | Stores live conversation sessions, message turns, and runtime state | conversation_id, session_id, current_node_id, state, created_at |
| `ng_analytics.*` (schema) | Aggregated metrics, event records, and reporting data for conversation analytics | conversation_id, event_type, metric_name, value, recorded_at |
| `ng_simulation.*` (schema) | Simulation run definitions, replay inputs, and execution results | simulation_id, project_id, run_status, replay_payload, result_summary |

#### Access Patterns

- **Read**: Conversation engine reads decision tree nodes from `ng_design` at each turn to determine the next response; analytics queries aggregate over `ng_analytics` on demand; simulation reads `ng_simulation` run definitions for replay execution.
- **Write**: Each conversation turn persists a message and state snapshot to `ng_engine`; analytics events are written after each turn; simulation results are written on run completion; design changes from the admin frontend are persisted to `ng_design`.
- **Indexes**: Not discoverable from the DSL inventory. Refer to migration files managed by `node-pg-migrate` for index definitions.

---

### AIGO Redis Cache (`continuumAigoRedisCache`)

| Property | Value |
|----------|-------|
| Type | Redis |
| Architecture ref | `continuumAigoRedisCache` |
| Purpose | Cache and transient state store for SSE tokens, event recovery, and distributed coordination |
| Ownership | owned |
| Migrations path | Not applicable (schema-free) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| SSE token entries | Short-lived tokens enabling the Chat Widget to authenticate SSE streams | token_key, conversation_id, expiry |
| Event recovery buffers | Transient event state enabling at-least-once delivery for in-flight SSE pushes | event_id, payload, retry_count |
| Distributed coordination locks | Prevent duplicate processing of concurrent conversation turns | lock_key, owner_id, ttl |

#### Access Patterns

- **Read**: Backend reads SSE tokens on widget connection to validate stream authorization; reads locks before processing each conversation turn.
- **Write**: Backend writes SSE tokens on conversation initiation; acquires/releases locks around critical sections in `backendConversationEngine`.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumAigoRedisCache` | Redis | SSE token storage, event recovery buffers, distributed locks | Short-lived (token/lock TTL not specified in inventory) |

## Data Flows

Conversation data originates in `ng_engine` as turns are processed by `backendConversationEngine`. Aggregated analytics records are derived from engine events and written to `ng_analytics` by `backendSimulationAndAnalytics`. Simulation runs read from `ng_design` to reconstruct tree state and write results to `ng_simulation`. No CDC, ETL pipelines, or cross-store replication are documented in the inventory.
