---
service: "liteLLM"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "postgresql"
    type: "postgresql"
    purpose: "Model configuration and metadata persistence"
  - id: "redis"
    type: "redis"
    purpose: "LLM response caching"
---

# Data Stores

## Overview

LiteLLM uses two data stores: a PostgreSQL database for model configuration persistence and a Redis/Memorystore cluster for LLM response caching. PostgreSQL is enabled when `STORE_MODEL_IN_DB=true` (set by default). Redis is always active with a 300-second TTL. Both are managed externally (database provider / GCP Memorystore / AWS ElastiCache) with backup and replication handled by the provider.

## Stores

### PostgreSQL — Model Configuration Database

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `unknown_postgresqldatabase_21193b78` (stub in DSL) |
| Purpose | Persists model definitions, virtual key configuration, and router metadata |
| Ownership | external (managed database provider; credentials via secret submodule) |
| Migrations path | `DISABLE_SCHEMA_UPDATE: "true"` is set — schema migrations are disabled in all environments |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Model configurations | Stores LiteLLM model definitions (provider, API key refs, routing weights) | model name, provider, deployment params |
| Virtual keys | API key records for internal consumer access control | key hash, spend limits, metadata |
| Spend tracking | Per-model and per-user budget and token usage records | user id, model, tokens, cost |

#### Access Patterns

- **Read**: Config Resolver (`gatewayConfigResolver`) reads model configuration at request routing time.
- **Write**: Admin API writes model definitions and virtual key records. LiteLLM writes spend/usage records after each request.
- **Indexes**: Not directly observable from this repo; managed by LiteLLM's internal schema.

### Redis — Response Cache

| Property | Value |
|----------|-------|
| Type | redis |
| Architecture ref | Referenced via `REDIS_HOST` / `REDIS_PORT` env vars |
| Purpose | Caches LLM responses to reduce upstream provider API calls and latency |
| Ownership | external (GCP Memorystore in GCP environments; AWS ElastiCache in EU production) |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Response cache entries | Cached LLM completions keyed by request hash | request hash, response payload |

#### Access Patterns

- **Read**: LiteLLM checks cache before forwarding to provider; cache hit returns response immediately.
- **Write**: LiteLLM writes response to cache after each successful provider call.
- **Indexes**: Key-value store — no secondary indexes.

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `litellm-default-memorystore` (GCP) | redis | LLM response caching | 300 seconds |
| `litellm-default-elasticache` (AWS EU) | redis | LLM response caching | 300 seconds |

## Data Flows

- On each inference request: LiteLLM reads model config from PostgreSQL (or in-memory cache of DB config), checks Redis for a cached response, and — on miss — forwards to the upstream LLM provider.
- Provider response is written to Redis and returned to the caller.
- Token usage and cost are written back to PostgreSQL for spend tracking and Prometheus metrics.
- Langfuse callback receives prompt + response for observability logging.
