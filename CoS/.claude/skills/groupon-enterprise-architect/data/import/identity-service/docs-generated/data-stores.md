---
service: "identity-service"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores:
  - id: "continuumIdentityServicePrimaryPostgres"
    type: "postgresql"
    purpose: "Primary identity store — identities, API keys, message bus message log"
  - id: "continuumIdentityServiceRedis"
    type: "redis"
    purpose: "Identity data cache and Resque job queue"
  - id: "continuumIdentityServiceMysql"
    type: "mysql"
    purpose: "PWA platform identity data (shared store)"
---

# Data Stores

## Overview

identity-service owns a PostgreSQL database as its primary store for identity records, API keys, and the message bus message log. Redis serves dual purposes: it caches frequently accessed identity data and backs the Resque job queue used by the Mbus consumer worker. The service also accesses a MySQL database for PWA platform identity data, which is a shared store (not exclusively owned by this service).

## Stores

### Primary PostgreSQL (`continuumIdentityServicePrimaryPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumIdentityServicePrimaryPostgres` |
| Purpose | Authoritative store for user identity records, service API keys, and Message Bus message log |
| Ownership | owned |
| Migrations path | `db/migrate/` (to be confirmed by service owner) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `identities` | Core user identity records | uuid (PK), attributes, created_at, updated_at, erased_at |
| `api_keys` | Service-to-service authentication keys | key_hash, service_name, created_at, revoked_at |
| `message_bus_messages` | Outbox log for Message Bus event publishing (ensures at-least-once delivery) | id, topic, payload, published_at, created_at |

#### Access Patterns

- **Read**: Identity lookups by UUID (primary key) from the HTTP API; bulk reads during GDPR erasure processing
- **Write**: Identity creation and update from HTTP API handlers; identity erasure (soft or hard delete) from the Mbus consumer worker; outbox writes on each identity lifecycle event
- **Indexes**: UUID primary key index on `identities`; additional indexes to be confirmed by service owner

### MySQL / PWA (`continuumIdentityServiceMysql`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | (shared store — no dedicated Structurizr container ID) |
| Purpose | PWA platform identity data; bridged via mysql2 adapter |
| Ownership | shared |
| Migrations path | Managed by PWA platform team |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| PWA identity tables | PWA-specific identity data bridged from Continuum | To be confirmed by service owner |

#### Access Patterns

- **Read**: Cross-platform identity lookups required for PWA integration
- **Write**: Identity sync writes from Continuum to PWA platform
- **Indexes**: To be confirmed

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| `continuumIdentityServiceRedis` | redis | Identity data cache — reduces read load on PostgreSQL for frequent lookups | To be confirmed |
| `continuumIdentityServiceRedis` (Resque) | redis | Resque job queue backing store for Mbus consumer worker | Not applicable (queue) |

## Data Flows

- **HTTP API to PostgreSQL**: Synchronous reads and writes on every identity CRUD request.
- **HTTP API to Redis**: Cache writes on identity creation/update; cache reads on identity lookup (cache-aside pattern).
- **Mbus Consumer to PostgreSQL**: Erasure worker reads and removes identity data from PostgreSQL on GDPR erasure requests.
- **Resque job dispatch**: Mbus consumer enqueues background jobs via Redis; workers dequeue and process asynchronously.
- **PostgreSQL outbox to Message Bus**: The `message_bus_messages` table acts as a transactional outbox; a relay process (or in-process publisher) reads and publishes undelivered events to the Message Bus.
